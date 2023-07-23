local ht = require('haskell-tools')
local Path = require('plenary.path')

local cwd = vim.fn.getcwd()
local cabal_project_root = cwd .. '/tests/fixtures/cabal/multi-package'
local stack_project_root = cwd .. '/tests/fixtures/stack/multi-package'
local invalid_project_path = '/some/invalid/path'

describe('Project API', function()
  ht.setup()
  it('Public API is available after setup.', function()
    assert(ht.project ~= nil)
  end)
  describe('Cabal:', function()
    it('Can detect project root', function()
      assert.same(cabal_project_root, ht.project.root_dir(cabal_project_root .. '/sub1/src/Lib.hs'))
    end)
  end)
  describe('Stack:', function()
    it('Can detect project root', function()
      assert.same(stack_project_root, ht.project.root_dir(stack_project_root .. '/sub1/src/Lib.hs'))
    end)
  end)
  describe('Non-project:', function()
    it('project_root returns nil', function()
      assert.same(nil, ht.project.root_dir(cwd))
    end)
    it('project_root returns nil', function()
      assert.same(nil, ht.project.root_dir(invalid_project_path))
    end)
  end)
end)

describe('Internal project utils:', function()
  local project_util = require('haskell-tools.project.util')
  describe('Cabal:', function()
    it('Can find project root.', function()
      local project_root = project_util.match_project_root(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root, project_root)
    end)
    it('Can find package root.', function()
      local project_root = project_util.match_package_root(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub1', project_root)
      project_root = project_util.match_package_root(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub2', project_root)
    end)
    it('Can detect cabal project.', function()
      assert(project_util.is_cabal_project(cabal_project_root .. '/sub1/src/Lib.hs'))
      assert(project_util.is_cabal_project(cabal_project_root .. '/sub2/src/Lib.hs'))
    end)
    it('Can get package file.', function()
      local package_cabal_file = project_util.get_package_cabal(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub1/sub1.cabal', package_cabal_file)
      package_cabal_file = project_util.get_package_cabal(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub2/sub2.cabal', package_cabal_file)
    end)
    it('Can determine package name.', function()
      local package_name = project_util.get_package_name(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same('sub1', package_name)
      package_name = project_util.get_package_name(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same('sub2', package_name)
    end)
  end)
  describe('Stack:', function()
    it('Can find project root.', function()
      local project_root = project_util.match_project_root(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root, project_root)
    end)
    it('Can find package root.', function()
      local project_root = project_util.match_package_root(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root .. '/sub1', project_root)
      project_root = project_util.match_package_root(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same(stack_project_root .. '/sub2', project_root)
    end)
    it('Can detect stack project.', function()
      assert(project_util.is_stack_project(stack_project_root .. '/sub1/src/Lib.hs'))
      assert(project_util.is_stack_project(stack_project_root .. '/sub2/src/Lib.hs'))
    end)
    it('Can get package file.', function()
      local package_yaml_file = project_util.get_package_yaml(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root .. '/sub1/package.yaml', package_yaml_file)
      package_yaml_file = project_util.get_package_yaml(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same(stack_project_root .. '/sub2/package.yaml', package_yaml_file)
    end)
    it('Can determine package name.', function()
      local package_name = project_util.get_package_name(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same('sub1', package_name)
      package_name = project_util.get_package_name(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same('sub2', package_name)
    end)
  end)

  local function test_non_project(non_project_path)
    it('match_project_root returns nil', function()
      assert.same(nil, project_util.match_project_root(non_project_path))
    end)
    it('match_package_root returns nil', function()
      assert.same(nil, project_util.match_package_root(non_project_path))
    end)
    it('is_cabal_project returns false', function()
      assert.same(false, project_util.is_cabal_project(non_project_path))
    end)
    it('is_stack_project returns false', function()
      assert.same(false, project_util.is_stack_project(non_project_path))
    end)
  end

  describe('Non-project (valid path):', function()
    test_non_project(cwd)
  end)
  describe('Non-project (invalid path):', function()
    test_non_project(invalid_project_path)
  end)

  describe('Cabal project', function()
    it('Can parse multiple package paths', function()
      local project_file = Path:new('tests/fixtures/cabal/multi-package/cabal.project').filename
      local package_paths = project_util.parse_package_paths(project_file)
      assert.equals(2, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)
    it('Can parse single package path', function()
      local project_file = Path:new('tests/fixtures/cabal/single-package/cabal.project').filename
      local package_paths = project_util.parse_package_paths(project_file)
      assert.equals(1, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)

    local expected_entry_points = {
      {
        package_name = 'sub1',
        package_dir = 'tests/fixtures/cabal/multi-package/sub1',
        exe_name = 'app',
        main = 'Main.hs',
        source_dir = 'app',
      },
      {
        package_name = 'sub1',
        package_dir = 'tests/fixtures/cabal/multi-package/sub1',
        exe_name = 'tests',
        main = 'Spec.hs',
        source_dir = 'test',
      },
    }
    it('Can parse package entry points.', function()
      local package_dir = Path:new('tests/fixtures/cabal/multi-package/sub1').filename
      local entry_points = project_util.parse_package_entrypoints(package_dir)
      assert.same(expected_entry_points, entry_points)
    end)
    it('Can parse project entry points.', function()
      local project_dir = Path:new('tests/fixtures/cabal/multi-package').filename
      local entry_points = project_util.parse_project_entrypoints(project_dir)
      assert.same(expected_entry_points, entry_points)
    end)
  end)

  describe('Stack project', function()
    it('Can parse multi package paths', function()
      local project_file = Path:new('tests/fixtures/stack/multi-package/stack.yaml').filename
      local package_paths = project_util.parse_package_paths(project_file)
      assert.equals(2, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)
    it('Can parse single package path', function()
      local project_file = Path:new('tests/fixtures/stack/single-package/stack.yaml').filename
      local package_paths = project_util.parse_package_paths(project_file)
      assert.equals(1, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)

    local expected_entry_points = {
      {
        package_name = 'sub1',
        package_dir = 'tests/fixtures/stack/multi-package/sub1',
        exe_name = 'sub1',
        main = 'Main.hs',
        source_dir = 'app',
      },
      {
        package_name = 'sub1',
        package_dir = 'tests/fixtures/stack/multi-package/sub1',
        exe_name = 'sub1-spec',
        main = 'Spec.hs',
        source_dir = 'test',
      },
    }
    it('Can parse package entry points.', function()
      local package_dir = Path:new('tests/fixtures/stack/multi-package/sub1').filename
      local entry_points = project_util.parse_package_entrypoints(package_dir)
      assert.same(expected_entry_points, entry_points)
    end)
    it('Can parse project entry points.', function()
      local project_dir = Path:new('tests/fixtures/stack/multi-package').filename
      local entry_points = project_util.parse_project_entrypoints(project_dir)
      assert.same(expected_entry_points, entry_points)
    end)
  end)
end)
