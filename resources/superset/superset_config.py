# Superset specific config
# SS 相关的配置
# 行数限制 5000 行
ROW_LIMIT = 5000

# 网站服务器端口 8088
SUPERSET_WEBSERVER_PORT = 8088

# Flask App Builder configuration
# Your App secret key will be used for securely signing the session cookie
# and encrypting sensitive information on the database
# Make sure you are changing this key for your deployment with a strong key.
# You can generate a strong key using `openssl rand -base64 42`
# Flask 应用构建器配置
# 应用密钥用来保护会话 cookie 的安全签名
# 并且用来加密数据库中的敏感信息
# 请确保在你的部署环境选择一个强密钥
# 可以使用命令 openssl rand -base64 42 来生成一个强密钥

SECRET_KEY = "ZT2uRVAMPKpVkHM/QA1QiQlMuUgAi7LLo160AHA99aihEjp03m1HR6Kg"

# The SQLAlchemy connection string to your database backend
# This connection defines the path to the database that stores your
# superset metadata (slices, connections, tables, dashboards, ...).
# Note that the connection information to connect to the datasources
# you want to explore are managed directly in the web UI
# SQLAlchemy 数据库连接信息
# 这个连接信息定义了 SS 元数据库的路径（切片、连接、表、数据面板等等）
# 注意：需要探索的数据源连接及数据库连接直接通过网页界面进行管理
#SQLALCHEMY_DATABASE_URI = 'sqlite:path/to/superset.db'

# Flask-WTF flag for CSRF
# 跨域请求攻击标识
WTF_CSRF_ENABLED = True

# Add endpoints that need to be exempt from CSRF protection
# CSRF 白名单
WTF_CSRF_EXEMPT_LIST = []

# A CSRF token that expires in 1 year
# CSFR 令牌过期时间 1 年
WTF_CSRF_TIME_LIMIT = 60 * 60 * 24 * 365

# Set this API key to enable Mapbox visualizations
# 接口密钥用来启用 Mapbox 可视化
MAPBOX_API_KEY = ''
