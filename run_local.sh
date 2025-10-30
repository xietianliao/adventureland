#!/bin/bash
#
# Adventure Land - macOS 一键启动脚本
# 启动 Python2.7 本地服务 + Node 游戏服务器

# ============= 基础设置 =============
PYTHON_VERSION="2.7.18"
NODE_PORT=8022
GAME_REGION="EU"
GAME_ID="I"
PYTHON_PORT=8080

# 当前项目根路径（自动取当前脚本所在目录）
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# ============= 环境初始化 =============
echo "👉 初始化 pyenv 环境..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# 检查 Python 版本
CURRENT_PY=$(python --version 2>&1)
if [[ "$CURRENT_PY" != *"$PYTHON_VERSION"* ]]; then
  echo "⚠️ 当前 Python 版本不是 $PYTHON_VERSION，尝试切换..."
  pyenv shell $PYTHON_VERSION
fi

# 检查 Flask 与 lxml
echo "✅ 检查依赖..."
pip2.7 show flask >/dev/null 2>&1 || pip2.7 install flask -t "$PROJECT_ROOT/lib"
pip2.7 show lxml >/dev/null 2>&1 || pip2.7 install lxml

# ============= 启动 Python 后端 =============
echo "🚀 启动 Adventure Land Python 后端服务..."
cd "$PROJECT_ROOT/appserver"
python2.7 sdk/dev_appserver.py \
  --storage_path=storage/ \
  --blobstore_path=storage/blobstore/ \
  --datastore_path=storage/db.rdbms \
  --host=0.0.0.0 \
  --port=$PYTHON_PORT \
  "$PROJECT_ROOT/app.yaml" \
  --require_indexes --skip_sdk_update_check &

PY_PID=$!
sleep 3

# ============= 启动 Node 游戏服务器 =============
echo "🚀 启动 Adventure Land Node 游戏服务器..."
cd "$PROJECT_ROOT/node"
if ! command -v node >/dev/null 2>&1; then
  echo "⚠️ 未检测到 Node.js，请先安装： brew install node"
  exit 1
fi
npm install >/dev/null 2>&1
node server.js $GAME_REGION $GAME_ID $NODE_PORT &

NODE_PID=$!

# ============= 运行提示 =============
echo ""
echo "✅ Adventure Land 已启动成功！"
echo "-----------------------------------------"
echo "🧩 Python 后端端口:  http://127.0.0.1:$PYTHON_PORT/"
echo "🎮 Node 游戏服务器:  ws://127.0.0.1:$NODE_PORT/"
echo "🌍 打开浏览器访问:   http://127.0.0.1/"
echo "-----------------------------------------"
echo "要停止所有服务，请按 Ctrl + C"
echo ""

# ============= 等待退出 =============
wait $PY_PID $NODE_PID
