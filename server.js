const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
const host = '0.0.0.0';

app.get('/healthy', (req, res) => {
    // 預設為 'unknown'，如果沒有設定 NODE_ENV
    const currentEnv = process.env.NODE_ENV || 'dev'; 
    
    // 確保只回傳預期的環境名稱
    const allowedEnvs = ['dev', 'staging', 'production'];
    if (allowedEnvs.includes(currentEnv)) {
        return res.status(200).json({ status: 'healthy', environment: currentEnv });
    } else {
        // 如果 NODE_ENV 不在預期列表中，可以回傳一個預設值
        return res.status(200).json({ status: 'healthy', environment: 'unknown' });
    }
});

app.listen(port, host, () => {
    console.log(`Healthy API listening at http://${host}:${port}, running in ${process.env.NODE_ENV || 'unknown'} environment`);
});
