const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
const git = require('simple-git');

app.get('/healthy', async (req, res) => {
    try {
        const branchSummary = await git().branchLocal();
        const currentBranch = branchSummary.current;

        // 確保只回傳預期的分支名稱
        const allowedBranches = ['dev', 'staging', 'production'];
        if (allowedBranches.includes(currentBranch)) {
            return res.status(200).json({ status: 'healthy', branch: currentBranch });
        } else {
            // 如果分支不在預期列表中，可以回傳一個預設值或錯誤
            return res.status(200).json({ status: 'healthy', branch: 'unknown' });
        }
    } catch (error) {
        console.error('Failed to get Git branch:', error);
        return res.status(500).json({ status: 'unhealthy', error: 'Could not determine branch' });
    }
});

app.listen(port, () => {
    console.log(`Healthy API listening at http://localhost:${port}`);
});
