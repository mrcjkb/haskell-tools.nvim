local cwd = vim.fn.getcwd() or '.'
local cabal_project_root = cwd .. '/spec/fixtures/cabal/multi-package'
local stack_project_root = cwd .. '/spec/fixtures/stack/multi-package'
local invalid_project_path = '/some/invalid/path'

describe('Project API', function()
  local ht = require('haskell-tools')
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

describe('Internal project helpers:', function()
  local HtProjectHelpers = require('haskell-tools.project.helpers')
  describe('Cabal:', function()
    it('Can find project root.', function()
      local project_root = HtProjectHelpers.match_project_root(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root, project_root)
    end)
    it('Can find package root.', function()
      local project_root = HtProjectHelpers.match_package_root(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub1', project_root)
      project_root = HtProjectHelpers.match_package_root(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub2', project_root)
    end)
    it('Can detect cabal project.', function()
      assert(HtProjectHelpers.is_cabal_project(cabal_project_root .. '/sub1/src/Lib.hs'))
      assert(HtProjectHelpers.is_cabal_project(cabal_project_root .. '/sub2/src/Lib.hs'))
    end)
    it('Can get package file.', function()
      local package_cabal_file = HtProjectHelpers.get_package_cabal(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub1/sub1.cabal', package_cabal_file)
      package_cabal_file = HtProjectHelpers.get_package_cabal(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same(cabal_project_root .. '/sub2/sub2.cabal', package_cabal_file)
    end)
    it('Can determine package name.', function()
      local package_name = HtProjectHelpers.get_package_name(cabal_project_root .. '/sub1/src/Lib.hs')
      assert.same('sub1', package_name)
      package_name = HtProjectHelpers.get_package_name(cabal_project_root .. '/sub2/src/Lib.hs')
      assert.same('sub2', package_name)
    end)
  end)
  describe('Stack:', function()
    it('Can find project root.', function()
      local project_root = HtProjectHelpers.match_project_root(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root, project_root)
    end)
    it('Can find package root.', function()
      local project_root = HtProjectHelpers.match_package_root(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root .. '/sub1', project_root)
      project_root = HtProjectHelpers.match_package_root(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same(stack_project_root .. '/sub2', project_root)
    end)
    it('Can detect stack project.', function()
      assert(HtProjectHelpers.is_stack_project(stack_project_root .. '/sub1/src/Lib.hs'))
      assert(HtProjectHelpers.is_stack_project(stack_project_root .. '/sub2/src/Lib.hs'))
    end)
    it('Can get package file.', function()
      local package_yaml_file = HtProjectHelpers.get_package_yaml(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same(stack_project_root .. '/sub1/package.yaml', package_yaml_file)
      package_yaml_file = HtProjectHelpers.get_package_yaml(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same(stack_project_root .. '/sub2/package.yaml', package_yaml_file)
    end)
    it('Can determine package name.', function()
      local package_name = HtProjectHelpers.get_package_name(stack_project_root .. '/sub1/src/Lib.hs')
      assert.same('sub1', package_name)
      package_name = HtProjectHelpers.get_package_name(stack_project_root .. '/sub2/src/Lib.hs')
      assert.same('sub2', package_name)
    end)
  end)

  local function test_non_project(non_project_path)
    it('match_project_root returns falsy', function()
      assert(not HtProjectHelpers.match_project_root(non_project_path))
    end)
    it('match_package_root returns falsy', function()
      assert(not HtProjectHelpers.match_package_root(non_project_path))
    end)
    it('is_cabal_project returns false', function()
      assert.same(false, HtProjectHelpers.is_cabal_project(non_project_path))
    end)
    it('is_stack_project returns false', function()
      assert.same(false, HtProjectHelpers.is_stack_project(non_project_path))
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
      local project_file = 'spec/fixtures/cabal/multi-package/cabal.project'
      local package_paths = HtProjectHelpers.parse_package_paths(project_file)
      assert.equal(2, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)
    it('Can parse single package path', function()
      local project_file = 'spec/fixtures/cabal/single-package/cabal.project'
      local package_paths = HtProjectHelpers.parse_package_paths(project_file)
      assert.equal(1, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)

    local expected_entry_points = {
      {
        package_name = 'sub1',
        package_dir = 'spec/fixtures/cabal/multi-package/sub1',
        exe_name = 'app',
        main = 'Main.hs',
        source_dir = 'app',
      },
      {
        package_name = 'sub1',
        package_dir = 'spec/fixtures/cabal/multi-package/sub1',
        exe_name = 'tests',
        main = 'Spec.hs',
        source_dir = 'test',
      },
    }
    it('Can parse package entry points.', function()
      local package_dir = 'spec/fixtures/cabal/multi-package/sub1'
      local entry_points = HtProjectHelpers.parse_package_entrypoints(package_dir)
      assert.same(expected_entry_points, entry_points)
    end)
    it('Can parse project entry points.', function()
      local project_dir = 'spec/fixtures/cabal/multi-package'
      local entry_points = HtProjectHelpers.parse_project_entrypoints(project_dir)
      assert.same(expected_entry_points, entry_points)
    end)
  end)

  describe('Stack project', function()
    it('Can parse multi package paths', function()
      local project_file = 'spec/fixtures/stack/multi-package/stack.yaml'
      local package_paths = HtProjectHelpers.parse_package_paths(project_file)
      assert.equal(2, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)
    it('Can parse single package path', function()
      local project_file = 'spec/fixtures/stack/single-package/stack.yaml'
      local package_paths = HtProjectHelpers.parse_package_paths(project_file)
      assert.equal(1, #package_paths)
      for _, path in pairs(package_paths) do
        assert(vim.fn.isdirectory(path) == 1)
      end
    end)

    local expected_entry_points = {
      {
        package_name = 'sub1',
        package_dir = 'spec/fixtures/stack/multi-package/sub1',
        exe_name = 'sub1',
        main = 'Main.hs',
        source_dir = 'app',
      },
      {
        package_name = 'sub1',
        package_dir = 'spec/fixtures/stack/multi-package/sub1',
        exe_name = 'sub1-spec',
        main = 'Spec.hs',
        source_dir = 'test',
      },
    }
    it('Can parse package entry points.', function()
      local package_dir = 'spec/fixtures/stack/multi-package/sub1'
      local entry_points = HtProjectHelpers.parse_package_entrypoints(package_dir)
      assert.same(expected_entry_points, entry_points)
    end)
    it('Can parse project entry points.', function()
      local project_dir = 'spec/fixtures/stack/multi-package'
      local entry_points = HtProjectHelpers.parse_project_entrypoints(project_dir)
      assert.same(expected_entry_points, entry_points)
    end)
  end)
end)
