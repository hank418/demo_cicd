# 使用官方 Node.js 18 LTS 映像作為基礎映像
FROM node:18-alpine

# 設定工作目錄
WORKDIR /app

# 複製 package.json 和 package-lock.json 到工作目錄
COPY package*.json ./

# 安裝專案依賴
RUN npm install

# 複製所有應用程式檔案到工作目錄
COPY . .

# 暴露應用程式監聽的 port
EXPOSE 3000

# 定義啟動命令
CMD ["npm", "start"]
