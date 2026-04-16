# ========================================
# Start Kratos Dev Adventure
# 开始你的 Kratos 开发之旅吧
# ========================================

# These dev tools make Kratos projects a breeze! Run make init to set up
# 这些是我专为 Kratos 项目打造的效率工具，让开发变得更轻松愉快！请运行 make init 安装
init:
	@echo "正在安装 Kratos 相关的开发工具链..."
	# orzkratos-add-proto: No more tedious proto file creation!
	# Usage: Run orzkratos-add-proto demo.proto in api/ DIR
	#
	# orzkratos-add-proto: 告别繁琐的 proto 文件手动创建！
	# 使用方法: 在 api/ 目录下运行 orzkratos-add-proto demo.proto
	go install github.com/yylego/kratos-orz/cmd/orzkratos-add-proto@latest

	# orzkratos-srv-proto: Auto sync magic, keeps service implementations aligned with proto definitions
	# IMPORTANT: Backup code (commit to git) first, since it modifies source files
	#
	# orzkratos-srv-proto: 自动同步神器，让你的服务实现与 proto 接口始终保持一致
	# 重要提醒: 使用前请务必备份代码或提交到 git，因为会直接修改源文件
	go install github.com/yylego/kratos-orz/cmd/orzkratos-srv-proto@latest

	# wirekratos: Enhanced Wire DI, supports Kratos workspace mode and framework markers
	# wirekratos: Wire 依赖注入增强工具，支持 Kratos 工作区模式和框架标识
	go install github.com/yylego/kratos-wire/cmd/wirekratos@latest

	# depbump: One-click deps upgrade, no more version headaches
	# depbump: 一键升级所有依赖包，告别版本管理烦恼
	go install github.com/yylego/depbump/cmd/depbump@latest

	# go-lint: Code guardian, auto format + static checks
	# go-lint: 代码质量守护者，自动格式化 + 静态检查
	go install github.com/yylego/go-lint/cmd/go-lint@latest

	# tago: Smart Git tag management, supports semantic version auto-increment
	# tago: 智能 Git tag 版本管理工具，支持语义化版本自动递增
	go install github.com/yylego/tago/cmd/tago@latest

	# go-commit: Git commit automation with Go code formatting
	# go-commit: Git 提交自动化工具，附带 Go 代码格式化功能
	go install github.com/yylego/go-commit/cmd/go-commit@latest

	# clang-format-batch: Batch format proto, cpp and more languages
	# clang-format-batch: 批量格式化 proto 和 cpp 等多种语言代码
	go install github.com/yylego/clang-format/cmd/clang-format-batch@latest

	# protoc-gen-orzkratos-errors: Auto generate Go code from proto definitions, provides enum codes and nested functions
	# protoc-gen-orzkratos-errors: proto 错误定义自动生成 Go 代码，提供错误码枚举和错误嵌套功能
	go install github.com/yylego/kratos-errgen/cmd/protoc-gen-orzkratos-errors@latest
	@echo "✅ 工具安装完成！现在可以开始愉快地开发啦"

# Format code in projects via command line
# 使用命令行整理项目中的代码
fmt:
	@echo "开始整理所有演示项目的代码..."
	cd demo1kratos && clang-format-batch --extensions=proto
	cd demo2kratos && clang-format-batch --extensions=proto
	@echo "✅ 所有项目的代码整理完成！"

# Build demo projects, includes proto generation, config processing, code generation, etc.
# 构建所有演示项目，包括 proto 生成、配置文件处理、代码生成等
all:
	@echo "开始构建所有演示项目..."
	cd demo1kratos && make all
	cd demo2kratos && make all
	@echo "✅ 所有项目构建完成！"

# ========================================
# Magic Command make orz - Auto Sync Proto Code with Service
# 魔法命令 make orz - 自动同步 Proto 代码与服务
# ========================================
# This is the most amazing feature! When you change proto files, run this command:
# Add interface → Auto add function implementation in service (adds stub, you implement the logic)
# Delete interface → Auto convert service method to unexported (avoids compile bugs)
# Sort functions → Sort service implementations based on proto definition sequence
# Usage:
#   1. Add CreateArticle interface in proto file
#   2. Run make orz
#   3. Service auto generates CreateArticle method stub, just add business logic!
#
# 这是最强大的功能！当你修改 proto 文件后，运行这个命令：
# 新增接口 → 自动在服务层添加对应的函数实现（新增个空函数，需要您实现函数内部逻辑）
# 删除接口 → 自动将服务代码中对应的方法改为非导出的（避免编译错误）
# 函数排序 → 根据你 proto 里定义的函数顺序重新排列服务里的实现代码
# 使用场景举例:
#   1. 在 proto 文件中新增了 CreateArticle 接口
#   2. 运行 make orz
#   3. 服务层自动生成 CreateArticle 方法框架，你只需要填充业务逻辑！
orz:
	@echo "开始执行 Proto-Service 自动同步..."
	cd demo1kratos && make all && orzkratos-srv-proto -auto
	cd demo2kratos && make all && orzkratos-srv-proto -auto
	@echo "✅ 同步完成！请检查生成的代码并完善业务逻辑"

# ========================================
# TEMPLATE BEGIN: TEST AND COVERAGE CONFIG
# 模板开始: 测试和覆盖率配置
# ========================================
# Test and Coverage (GitHub Actions)
# 测试和覆盖率（GitHub Actions 自动执行）
# ========================================

# Coverage output DIR
# 覆盖率输出目录
COVERAGE_DIR ?= .coverage.out

# Reference: https://github.com/yylego/gormrepo/blob/main/Makefile
test:
	@if [ -d $(COVERAGE_DIR) ]; then rm -r $(COVERAGE_DIR); fi
	@mkdir $(COVERAGE_DIR)
	make test-with-flags TEST_FLAGS='-v -race -covermode atomic -coverprofile $$(COVERAGE_DIR)/combined.txt -bench=. -benchmem -timeout 20m'

# Run tests with custom flags
# 使用自定义参数运行测试
test-with-flags:
	@go test $(TEST_FLAGS) ./...

# ========================================
# TEMPLATE END: TEST AND COVERAGE CONFIG
# 模板结束: 测试和覆盖率配置
# ========================================

# ========================================
# Upgrade Source Project (This Project) - Complete Workflow
# 升级源项目（本项目）的完整流程
# ========================================
# Background:
# This project is a MULTI-MODULE repo with root + 2 sub-modules (demo1kratos, demo2kratos).
# The root module's go.mod references the sub-modules, which requires TWO INDEPENDENT ROUNDS:
#
#   Round 1 (source-round1-*): Upgrade and release SUB-MODULES only
#   Round 2 (source-round2-*): Upgrade and release ROOT module only
#
# Sub-modules must be tagged FIRST so root can reference the new sub-module versions in Round 2.
#
# IMPORTANT: source-round*-* is DESIGNED FOR THE SOURCE PROJECT ONLY.
# Fork projects should use merge-stepN series instead.
#
# 背景说明：
# 本项目是 MULTI-MODULE 仓库，包含根模块 + 2 个子模块（demo1kratos, demo2kratos）。
# 根模块的 go.mod 引用子模块，所以升级需要 两个独立的轮次：
#
#   轮次 1（source-round1-*）: 只升级并发布 子模块
#   轮次 2（source-round2-*）: 只升级并发布 根模块
#
# 子模块必须先打标签，这样轮次 2 里根模块才能引用新的子模块版本。
#
# 重要：source-round*-* 专给源项目用，fork 项目请用 merge-stepN 系列。

# ========================================
# Round 1: Upgrade and Release SUB-MODULES (demo1kratos, demo2kratos)
# 轮次 1: 升级并发布 子模块（demo1kratos, demo2kratos）
# ========================================

# Round 1 Step 1: Confirm current project is the source project
# 轮次1步骤1: 确认当前是源项目
source-round1-step1:
	@ORIGIN_REPO=$$(git remote get-url origin 2>/dev/null || echo ""); \
	if echo "$$ORIGIN_REPO" | grep -q "yylego/kratos-examples.git"; then \
		echo "✅ 已确认当前是源项目，可以继续执行 source-round1-*"; \
	else \
		echo "❌ 错误: 当前不是源项目（yylego/kratos-examples）"; \
		echo "   当前 origin: $$ORIGIN_REPO"; \
		echo "   Fork 项目请使用 merge-stepN 系列命令"; \
		exit 1; \
	fi

# Round 1 Step 2: Upgrade sub-module dependencies (demo1kratos, demo2kratos)
# 轮次1步骤2: 升级子模块的依赖
source-round1-step2:
	# 只升级 demo1kratos 和 demo2kratos 的依赖，根模块暂时不管
	cd $(CURDIR)/demo1kratos && (depbump || depbump update -D)
	cd $(CURDIR)/demo2kratos && (depbump || depbump update -D)
	@echo "✅ 已升级子模块依赖"

# Round 1 Step 3: Tidy sub-module go.mod files
# 轮次1步骤3: 整理子模块的 go.mod
source-round1-step3:
	cd demo1kratos && go mod tidy -e
	cd demo2kratos && go mod tidy -e
	@echo "✅ 已整理子模块 go.mod"

# Round 1 Step 4: Regenerate proto/code in each sub-module
# 轮次1步骤4: 在各子模块里重新生成 proto 和代码
#
# Run 'make all' in each sub-module to regenerate proto code based on new dependencies.
# 在各子模块执行 make all 基于新依赖重新生成 proto 代码。
source-round1-step4:
	cd demo1kratos && make all
	cd demo2kratos && make all
	@echo "✅ 子模块代码已重新生成"

# Round 1 Step 5: Run sub-module tests
# 轮次1步骤5: 运行子模块测试
source-round1-step5:
	# -count=1 强制每次跑，不走测试缓存
	cd demo1kratos && go test -v -count=1 ./...
	cd demo2kratos && go test -v -count=1 ./...
	@echo "✅ 子模块测试通过"

# Round 1 Step 6: Run lint on sub-modules
# 轮次1步骤6: 子模块代码检查
source-round1-step6:
	# go-lint 是对 golangci-lint 的封装，支持多项目工作区
	go-lint
	@echo "✅ 代码检查通过"

# Round 1 Step 7: Commit sub-module upgrades
# 轮次1步骤7: 提交子模块升级
source-round1-step7:
	git diff --quiet || (git add -A && git commit -m "Upgrade sub-module deps")
	git status
	@echo "✅ 已提交子模块升级"

# Round 1 Step 8: Push main (first push)
# 轮次1步骤8: 推送 main（第一次推送）
source-round1-step8:
	git push origin main
	@echo "✅ 第一次推送完成，请等待 CI 通过后再执行 step9"

# Round 1 Step 9: Wait for CI to pass
# 轮次1步骤9: 等待 CI 通过
source-round1-step9:
	# 查看最新 run ID，然后用 gh run watch 等待
	gh run list --limit 2
	@echo "请执行: gh run watch <run-id> --exit-status"
	@echo "等待 CI 通过后再执行 step10 打子模块标签"

# Round 1 Step 10: Tag sub-modules only
# 轮次1步骤10: 只给子模块打标签
source-round1-step10:
	# 进入子模块目录分别打标签
	# tago bump sub-module -b=100 会基于子模块前缀自动递增版本（如 demo1kratos/v0.0.X），-b=100 表示免确认直接执行
	cd demo1kratos && tago bump sub-module -b=100
	cd demo2kratos && tago bump sub-module -b=100
	@echo "✅ 子模块标签已打并推送"
	@echo "   请等待 CI 通过以及标签对 go proxy 可用后再执行 Round 2"

# ========================================
# Round 2: Upgrade and Release ROOT module
# 轮次 2: 升级并发布 根模块
# ========================================
# Only run this AFTER Round 1 is complete AND sub-module tags are available on go proxy.
# Round 2 升级根模块的 go.mod，让它引用轮次 1 刚打的子模块新版本。
# 只在 Round 1 完成、且子模块标签在 go proxy 上可用后才执行。

# Round 2 Step 1: Upgrade root go.mod to use new sub-module versions
# 轮次2步骤1: 升级根模块 go.mod 引用新的子模块版本
#
# Round 1 刚打完子模块标签，go proxy 可能还没索引到。
# 先用 GOPROXY=direct 强制从 git 拉取最新子模块版本，绕过 proxy 缓存。
# 然后再 depbump 升级根模块的其他依赖。
#
# Round 1 just tagged sub-modules, go proxy may take a moment to index them.
# First use GOPROXY=direct to force-pull new sub-module versions from git (bypass proxy cache).
# Then run depbump to upgrade other deps in root module.
source-round2-step1:
	# 强制从 git 拉取刚打标签的子模块新版本（绕过 proxy 缓存）
	GOPROXY=direct go get github.com/yylego/kratos-examples/demo1kratos@latest
	GOPROXY=direct go get github.com/yylego/kratos-examples/demo2kratos@latest
	# 再用 depbump 升级根模块的其他依赖
	depbump || depbump update -D
	@echo "✅ 已升级根模块依赖"

# Round 2 Step 2: Tidy root go.mod
# 轮次2步骤2: 整理根模块 go.mod
source-round2-step2:
	go mod tidy -e
	@echo "✅ 已整理根模块 go.mod"

# Round 2 Step 3: Run root module tests
# 轮次2步骤3: 运行根模块测试
source-round2-step3:
	# -count=1 强制每次跑，不走测试缓存
	go test -v -count=1 ./...
	@echo "✅ 根模块测试通过"

# Round 2 Step 4: Run lint
# 轮次2步骤4: 代码检查
source-round2-step4:
	go-lint
	@echo "✅ 代码检查通过"

# Round 2 Step 5: Commit root go.mod upgrade
# 轮次2步骤5: 提交根模块升级
source-round2-step5:
	git diff --quiet || (git add -A && git commit -m "Upgrade root go.mod to use new sub-module versions")
	git status
	@echo "✅ 已提交根模块升级"

# Round 2 Step 6: Push main (second push)
# 轮次2步骤6: 推送 main（第二次推送）
source-round2-step6:
	git push origin main
	@echo "✅ 第二次推送完成，请等待 CI 通过后再执行 step7"

# Round 2 Step 7: Wait for CI to pass
# 轮次2步骤7: 等待 CI 通过
source-round2-step7:
	gh run list --limit 2
	@echo "请执行: gh run watch <run-id> --exit-status"
	@echo "等待 CI 通过后再执行 step8 打根模块标签"

# Round 2 Step 8: Tag root module
# 轮次2步骤8: 给根模块打标签
source-round2-step8:
	# 根模块打标签（如 v0.0.X），-b=100 表示免确认直接执行
	tago bump main -b=100
	@echo "✅ 根模块标签已打并推送"
	@echo "   下游 fork 项目现在可以通过 merge-stepN 同步这次的变更"

# ========================================
# Sync Upstream Repo Changes to Fork Project - Complete Workflow
# 同步上游仓库最新修改到 fork 项目的完整流程
# ========================================
# Background:
# 1. These projects are forked from kratos-examples, each demonstrates a specific usage technique to guide newcomers
# 2. In new fork projects, we also include test functions that compare code with the source kratos-examples project
# 3. When the source kratos-examples project is modified (including updated Kratos framework), you can sync changes in the fork project
# 4. These fork projects won't be merged back to kratos-examples, existing as standalone examples
# 5. The project provides source code sync logic, which can JUST be executed in fork projects
#
# 背景说明：
# 1. 这些项目都是由 kratos-examples fork 来的，而每个fork都会展示一种特殊的使用技巧，这样方便新手查看具体如何使用。
# 2. 在新 fork 项目里，还贴心的提供了和源项目 kratos-examples 代码的比较的测试函数
# 3. 当源项目 kratos-examples 修改了东西，或者使用了更新的 kratos 框架版本时，还可以在 fork 项目里同步修改。
# 4. 因此，这些 fork 的项目，基本都不会再合并到 kratos-examples 里，而是作为单独的样例长期存在。
# 5. 项目提供了同步源代码修改的逻辑，这个逻辑只能在 fork 项目里执行。
#
# Usage:
# 1. First check workspace status with git status, handle uncommitted changes:
#    - Just go.mod/go.sum changes: git stash (deps upgrade can be done next)
#    - Business code changes: commit first, avoid mixed commit records
# 2. Execute merge-step1 through merge-step12 in sequence to complete the sync
# 3. Resolve conflicts on own (common in go.mod/go.sum files)
# 4. If one step stops and code/deps need modification, re-run tests and lint to avoid introducing new bugs
#
# 使用说明：
# 1. 首先检查工作区状态 git status，如有未提交的修改需要处理：
#    - 仅包含 go.mod/go.sum 的变化：git stash (依赖升级可稍后再合)
#    - 有业务代码变化：需要先提交代码，避免混合提交历史
# 2. 按顺序执行 merge-step1 到 merge-step12 完成同步的操作
# 3. 如果有冲突，自行解决 (常见于 go.mod/go.sum 文件)
# 4. 若任何步骤出现错误需要再次修改代码/依赖时，改完都要再次运行测试和代码静态检查，避免引入新问题

# Step 1: Add upstream repo as remote source, handles duplicate add scenario
# 第1步: 添加上游仓库为远程源，智能处理重复添加的情况
merge-step1:
	# Add upstream repo as remote source, smart handling of duplicate add scenario
	# Note: If upstream remote exists and points to same repo, ignore duplicate, but if it points to a different repo, abort and stop
	# Check if current project is the source project itself
	#
	# 添加上游仓库为远程源，智能处理重复添加的情况
	# 注意: 如果 upstream 远程源已存在，而且是同名仓库，就忽略重复的错误，因为这不是问题，但是假如指向其他仓库，就报错，而且不往下执行
	# 检查当前是否是源项目本身
	@ORIGIN_REPO=$$(git remote get-url origin 2>/dev/null || echo ""); \
	if echo "$$ORIGIN_REPO" | grep -q "yylego/kratos-examples.git"; then \
		echo "⚠️  当前是源项目，该操作仅适用于 fork 项目"; \
		exit 1; \
	fi

	# Execute upstream repo add logic
	# 执行上游仓库添加逻辑
	@EXPECTED_REPO="git@github.com:yylego/kratos-examples.git"; \
	if git remote get-url upstream >/dev/null 2>&1; then \
		CURRENT_REPO=$$(git remote get-url upstream); \
		if [ "$$CURRENT_REPO" = "$$EXPECTED_REPO" ]; then \
			echo "upstream 远程源已存在且指向正确仓库: $$EXPECTED_REPO"; \
			echo "✅ 已确认上游仓库远程源"; \
		else \
			echo "❌ 错误: upstream 远程源已存在但指向不同仓库"; \
			echo "   当前指向: $$CURRENT_REPO"; \
			echo "   期望指向: $$EXPECTED_REPO"; \
			echo "   请手动处理: git remote remove upstream 或 git remote set-url upstream $$EXPECTED_REPO"; \
			exit 1; \
		fi; \
	else \
		echo "正在添加上游仓库远程源: $$EXPECTED_REPO"; \
		git remote add upstream "$$EXPECTED_REPO"; \
		echo "✅ 已添加上游仓库远程源"; \
	fi

# Step 2: Fetch upstream code without tags to avoid conflicts
# 第2步: 获取上游仓库的最新代码，不获取标签以避免冲突
merge-step2:
	# Fetch upstream code without tags to avoid conflicts
	# 获取上游仓库的最新代码，不获取标签以避免冲突
	git fetch --no-tags upstream main
	@echo "✅ 已获取上游仓库最新代码"
	# If you happened to sync source project tags, you can re-sync fork tags from remote
	# 假如你不小心已经同步源项目的标签，还可以这样让从远程完全同步子项目的标签
	# git fetch origin --tags --prune --prune-tags

# Step 3: Switch to main branch
# 第3步: 确保当前在 main 分支里
merge-step3:
	# Ensure on main branch
	# 确保当前在 main 分支里
	git checkout main
	@echo "✅ 已切换到 main 分支里"

# Step 4: Stash uncommitted changes if needed
# 第4步: 检查并暂存未提交的代码
merge-step4:
	# Check if there are uncommitted changes, stash them if needed
	# 检查当前是否有未提交的代码，如果有变动则暂存起来
	git status
	# If there are uncommitted changes, stash them (auto-detects changes)
	# 如果有未提交的变动，暂存到 stash（会自动检查是否有变动）
	git diff --quiet || git stash push -m "临时保存：merge 前的未提交变动"
	git status
	@echo "✅ 已检查并暂存未提交的代码（如果有的话）"

# Step 5: Merge upstream main branch
# 第5步: 合并上游仓库的 main 分支
merge-step5:
	# 合并上游仓库的 main 分支，使用 --no-edit 避免弹出编辑器，这样适合在脚本里执行
	git merge upstream/main --no-edit
	git status
	# 【重要提醒】假如出现冲突，请严格按照以下步骤操作：
	# 1. 编辑冲突文件，逐个解决所有 <<<<<<< ======= >>>>>>> 标记的冲突
	# 【技巧策略】假如是go.mod有冲突，在仅版本不同时，通过比较来挑选较新的版号
	# 【技巧策略】假如是go.sum有冲突，也可以不手动改，而是在解决完 go.mod 的冲突后执行 go mod tidy 即可解决
	# 2. 使用 git add <文件名> 将解决后的文件标记为已解决
	# 3. 继续合并流程：git merge --continue（绝对不要使用 git commit）
	# 【助手注意】在 merge 冲突场景下必须使用 git merge --continue 而非 git commit
	# 【再次强调】解决冲突后不要直接使用 git commit，这会破坏 merge 流程的状态管理
	@echo "✅ 已合并上游代码-请检查是否有冲突需要解决"

# Step 6: Continue merge after conflict resolution (skip if no conflicts)
# 第6步: 解决冲突后继续合并（无冲突则跳过）
merge-step6:
	# 假如 merge 无冲突则跳过这步就行
	# 当解决完所有冲突时，需要执行 git merge --continue
	# 检查是否还在 merge 状态，并判断冲突是否已全部解决
	@if [ -f .git/MERGE_HEAD ]; then \
		echo "检测到 merge 状态，检查冲突解决情况"; \
		if git diff --name-only --diff-filter=U | grep -q .; then \
			echo "⚠️  发现未解决的冲突文件："; \
			git diff --name-only --diff-filter=U; \
			echo "请手动解决所有冲突后再执行此步骤！"; \
			echo "解决完冲突以后请手动添加这些文件："; \
			for file in $$(git diff --name-only --diff-filter=U); do \
				echo "  git add $$file"; \
			done; \
			echo "或者添加全部：git add -A"; \
			exit 1; \
		else \
			echo "已解决所有冲突，继续合并代码"; \
			git merge --continue; \
		fi; \
	else \
		echo "merge 已完成，无需继续"; \
	fi
	git status
	@echo "✅ 已完成 merge 流程"

# Step 7: Upgrade all dependencies to latest versions
# 第7步: 升级所有项目的依赖包到最新版本
merge-step7:
	# 升级所有项目的依赖包到最新版本
	# 优先尝试 depbump -R 升级所有模块，失败则逐个升级
	@if depbump -R; then \
		echo "✅ depbump -R 已经成功升级所有模块"; \
	else \
		echo "⚠️ depbump -R 执行失败，改用逐个模块升级"; \
		echo "# depbump: 完整升级根目录依赖"; \
		echo "# depbump update -D: 升级直接依赖（-D 是默认的，优先用 depbump，出错时才用 depbump update -D）"; \
		depbump || depbump update -D; \
		echo "# 在项目根目录里进第1个项目，优先尝试完整升级，失败则使用仅直接依赖升级"; \
		cd $(CURDIR)/demo1kratos && (depbump || depbump update -D); \
		echo "# 在项目根目录里进第2个项目，优先尝试完整升级，失败则使用仅直接依赖升级"; \
		cd $(CURDIR)/demo2kratos && (depbump || depbump update -D); \
	fi
	# 注意: if-else 块内多条 cd 在同一个 shell 中执行，必须用 $(CURDIR) 绝对路径，否则第二个 cd 会基于第一个 cd 后的目录
	@echo "✅ 已升级所有依赖包"
	# 【备注】标准升级命令（使用 go get -u）：
	# depbump: 使用 go get -u ./... 升级当前模块依赖
	# depbump -R: 在工作区所有模块中使用 go get -u ./... 升级依赖
	# 【备注】智能升级命令（带 Go 版本兼容性检查，防止工具链传染）：
	# depbump bump: 智能升级直接依赖（等同于 depbump bump -D）
	# depbump bump -E: 智能升级所有依赖（直接+间接）
	# depbump bump -ER: 在工作区所有模块中智能升级所有依赖

# Step 8: Regenerate proto/code in each sub-module
# 第8步: 在各子模块重新生成 proto 和代码
#
# 依赖升级后，需要用 make all 根据新依赖重新生成 proto 代码。
# 如果跳过这步，可能用的是老版本生成的代码，测试通过但实际发布会有问题。
#
# After dep upgrades, run 'make all' to regenerate proto code based on new dependencies.
# Skipping this may leave stale generated code: tests pass but the release may break.
merge-step8:
	cd demo1kratos && make all
	cd demo2kratos && make all
	@echo "✅ 子模块代码已重新生成"

# Step 9: Commit dependency upgrades when changed
# 第9步: 提交依赖升级变动（如果有的话）
merge-step9:
	# 检查是否有依赖升级的变动，如果有则单独提交
	git diff --quiet || (git add -A && git commit -m "简单升级依赖包")
	git status
	@echo "✅ 已提交依赖升级变动（如果有的话）"

# Step 10: Run all tests to make sure code works
# 第10步: 运行所有测试确保代码正常工作
merge-step10:
	# 运行所有的测试确保代码正常工作
	# -count=1 强制每次跑，不走测试缓存
	go test -v -count=1 ./...
	# 在项目根目录里进第1个项目
	cd demo1kratos && go test -v -count=1 ./...
	# 在项目根目录里进第2个项目
	cd demo2kratos && go test -v -count=1 ./...
	@echo "✅ 已进行单元测试"

# Step 11: Tidy go.mod and go.sum files
# 第11步: 整理 go.mod 和 go.sum 文件
merge-step11:
	# 整理 go.mod 和 go.sum 文件
	# -e 参数允许在有错误时继续执行
	go mod tidy -e
	# 在项目根目录里进第1个项目
	cd demo1kratos && go mod tidy -e
	# 在项目根目录里进第2个项目
	cd demo2kratos && go mod tidy -e
	@echo "✅ 已整理所有依赖"

# Step 12: Run lint and code formatting
# 第12步: 运行代码静态检查和格式化
merge-step12:
	# 运行代码静态检查和格式化
	go-lint
	@echo "✅ 已进行代码检查"

# Step 13: Restore stashed changes when exist
# 第13步: 恢复之前暂存的代码（如果有的话）
merge-step13:
	# 恢复之前暂存的代码（如果有的话）
	# 检查是否有 stash 存在，如果有则恢复
	git stash list
	git stash list | grep -q "临时保存：merge 前的未提交变动" && git stash pop || echo "没有找到需要恢复的 stash"
	git status
	@echo "✅ 已恢复之前暂存的代码（如果有的话）"
