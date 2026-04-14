# DBHFit.jl 发布流程

## 📋 发布前检查清单

### 1. 代码质量检查

```bash
# 进入项目目录
cd d:\julia\DBHFit

# 运行测试
julia --project=. -e "using Pkg; Pkg.test()"

# 检查代码格式（可选）
julia -e "using JuliaFormatter; format(\"src/\")"
```

### 2. 更新版本号

编辑 `Project.toml`:
```toml
version = "0.1.0"  # 确认版本号正确
```

### 3. 更新CHANGELOG

编辑 `CHANGELOG.md`，记录本次发布的变更。

---

## 🚀 发布步骤

### 步骤1: 创建GitHub仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - Repository name: `DBHFit.jl`
   - Description: `专业的胸径(DBH)拟合Julia包`
   - Public
   - 不要勾选 "Add a README file"（我们已有）
   - License: MIT（我们已有）

3. 点击 "Create repository"

### 步骤2: 初始化Git并推送

```bash
# 进入项目目录
cd d:\julia\DBHFit

# 初始化Git
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial release v0.1.0"

# 设置主分支
git branch -M main

# 添加远程仓库（替换YOUR_USERNAME）
git remote add origin https://github.com/YOUR_USERNAME/DBHFit.jl.git

# 推送到GitHub
git push -u origin main
```

### 步骤3: 创建发布标签

```bash
# 创建标签
git tag v0.1.0

# 推送标签
git push origin v0.1.0
```

### 步骤4: 在GitHub创建Release

1. 访问 https://github.com/YOUR_USERNAME/DBHFit.jl/releases/new
2. 填写信息：
   - Tag: v0.1.0
   - Title: DBHFit.jl v0.1.0
   - Description: 复制CHANGELOG.md内容
3. 点击 "Publish release"

---

## 📦 注册到Julia General Registry

### 方式1: 自动注册（推荐）

1. 访问 https://github.com/JuliaRegistries/General
2. 点击 "Register a package"
3. 填写信息：
   - Package name: DBHFit
   - Repository: https://github.com/YOUR_USERNAME/DBHFit.jl
4. 提交注册请求

### 方式2: 手动注册

1. Fork https://github.com/JuliaRegistries/General
2. 在 `packages/` 目录创建文件：
   ```
   DBHFit/
   └── Package.toml
   ```
3. `Package.toml` 内容：
   ```toml
   name = "DBHFit"
   uuid = "b8c3d4e5-f6a7-8901-2345-6789abcdef01"
   repo = "https://github.com/YOUR_USERNAME/DBHFit.jl"
   ```
4. 提交Pull Request

### 步骤5: 等待审核

- Julia社区会审核你的包
- 通常1-3天完成
- 审核通过后，用户可以通过 `Pkg.add("DBHFit")` 安装

---

## ✅ 发布后验证

### 测试安装

```julia
# 在新的Julia环境中测试
julia> using Pkg

julia> Pkg.add("DBHFit")  # 注册后可用
# 或者
julia> Pkg.add(url="https://github.com/YOUR_USERNAME/DBHFit.jl")

julia> using DBHFit

julia> # 运行示例
julia> include("examples/basic_usage.jl")
```

---

## 📝 发布后维护

### 版本更新流程

1. 修改代码
2. 更新 `Project.toml` 版本号
3. 更新 `CHANGELOG.md`
4. 提交并推送：
   ```bash
   git add .
   git commit -m "Release v0.1.1"
   git tag v0.1.1
   git push origin main
   git push origin v0.1.1
   ```
5. 在GitHub创建新Release
6. 注册新版本（自动或手动）

### 遵循SemVer版本规范

- **主版本号（Major）**: 不兼容的API变更
- **次版本号（Minor）**: 向后兼容的功能新增
- **修订号（Patch）**: 向后兼容的问题修复

示例：
- `0.1.0` → `0.1.1`: Bug修复
- `0.1.1` → `0.2.0`: 新功能
- `0.2.0` → `1.0.0`: 重大变更

---

## 🔧 常见问题

### Q1: 测试失败怎么办？

```bash
# 查看详细错误信息
julia --project=. -e "using Pkg; Pkg.test()"

# 检查依赖
julia --project=. -e "using Pkg; Pkg.status()"
```

### Q2: 如何更新注册表信息？

提交PR到JuliaRegistries/General更新：
- 兼容性约束
- 版本号
- 依赖关系

### Q3: 如何添加文档？

推荐使用 Documenter.jl：
```julia
using Pkg
Pkg.add("Documenter")
```

创建 `docs/` 目录，配置自动文档生成。

---

## 📚 有用的链接

- [Julia包开发指南](https://pkgdocs.julialang.org/dev/)
- [JuliaRegistries](https://github.com/JuliaRegistries/General)
- [SemVer规范](https://semver.org/)
- [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/)

---

## 🎉 恭喜！

完成以上步骤后，你的包就可以被全球Julia用户使用了！

```julia
using Pkg
Pkg.add("DBHFit")
using DBHFit
```
