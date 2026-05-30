<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>业务查询</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: "Microsoft YaHei", sans-serif;
        }

        /* 顶部切换栏 */
        .tab-bar {
            display: flex;
            gap: 10px;
            padding: 14px 20px;
            background: #fff;
            border-bottom: 1px solid #eee;
            position: sticky;
            top: 0;
            z-index: 999;
            box-shadow: 0 2px 6px rgba(0,0,0,0.05);
        }

        /* 切换按钮 */
        .tab-btn {
            padding: 8px 16px;
            border: 1px solid #ddd;
            border-radius: 6px;
            background: #f9f9f9;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
        }

        .tab-btn.active {
            background: #0085d0;
            color: #fff;
            border-color: #0085d0;
        }

        .tab-btn:hover {
            border-color: #0085d0;
        }

        /* iframe 铺满页面 */
        #pageFrame {
            width: 100%;
            height: calc(100vh - 60px);
            border: none;
            display: block;
        }
    </style>
</head>
<body>

<!-- ====================== 你只需要改这里 ====================== -->
<div class="tab-bar">


    <button class="tab-btn" data-file="cha/yd.html">深圳查询</button>
</div>
<!-- =========================================================== -->

<!-- 页面容器（iframe 永不影响子页面功能） -->
<iframe id="pageFrame" src=""></iframe>

<script>
    // 默认打开的页面
    const defaultFile = "cha/yd.html";

    // 加载页面（带时间戳防缓存 + 不破坏任何功能）
    function loadPage(fileName) {
        const frame = document.getElementById('pageFrame');
        // 强制时间戳，防缓存
        const timestamp = Date.now();
        frame.src = `/${fileName}?t=${timestamp}`;
    }

    // 绑定选项卡点击
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const file = btn.getAttribute('data-file');
            loadPage(file);
        });
    });

    // 初始加载
    window.addEventListener('DOMContentLoaded', () => {
        loadPage(defaultFile);
    });
</script>

</body>
</html>