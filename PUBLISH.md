# 发布到 GitHub 指南

## 前置条件

- 已安装 Git
- 拥有 GitHub 账号

## 发布步骤

### 1. 在 GitHub 创建新仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角 **+** → **New repository**
3. 填写信息：
   - **Repository name**: `mac-paste`（或你喜欢的名字）
   - **Description**: `macOS 剪贴板历史管理器 - 轻量、美观的菜单栏工具`
   - 选择 **Public**
   - **不要**勾选 "Add a README file"（本地已有）
4. 点击 **Create repository**

### 2. 关联远程仓库并推送

在终端执行（将 `YOUR_USERNAME` 替换为你的 GitHub 用户名）：

```bash
cd /Users/veer/VibeCodingProjects/mac-paste

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/mac-paste.git

# 推送到 GitHub
git push -u origin main
```

若使用 SSH：

```bash
git remote add origin git@github.com:YOUR_USERNAME/mac-paste.git
git push -u origin main
```

### 3. 更新 README 中的链接

发布后，将 `README.md` 和 `CONTRIBUTING.md` 中的 `YOUR_USERNAME` 替换为你的实际 GitHub 用户名。

### 4. （可选）创建首个 Release

1. 在仓库页面点击 **Releases** → **Create a new release**
2. 填写版本号，如 `v1.0.0`
3. 可附上构建好的 `Paster.app`（需先 zip 打包）

---

完成！你的项目已成功开源到 GitHub。
