<%@ Language="VBScript" CodePage="65001" %>
<%
Response.CodePage = 65001
Response.Charset = "UTF-8"

' 从URL参数中获取token值
Dim tokenFromUrl
tokenFromUrl = Request.QueryString("token")
' 处理空值，避免出现undefined
If tokenFromUrl = "" Then
    tokenFromUrl = ""
End If
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>查询</title>
    <style>
        :root { --primary: #0085d0; --secondary: #eef7ff; --accent: #f60; --text-main: #333; --text-sub: #666; }
        body { font-family: "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif; background: #f0f2f5; margin: 0; padding: 20px 10px; color: var(--text-main); }
        
        /* 布局容器 */
        .container { max-width: 1200px; margin: 0 auto; display: flex; gap: 20px; align-items: flex-start; }
        .left-panel { flex: 0 0 380px; width: 380px; }
        .right-panel { flex: 1; min-width: 0; }

        @media (max-width: 900px) {
            .container { flex-direction: column; }
            .left-panel, .right-panel { width: 100%; flex: none; }
        }
        
        .card { background: #fff; border-radius: 12px; padding: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); margin-bottom: 15px; }
        .search-title { font-size: 18px; font-weight: bold; margin-bottom: 15px; color: var(--primary); }
        .input-group { margin-bottom: 12px; }
        .input-group label { display: block; font-size: 12px; color: var(--text-sub); margin-bottom: 4px; }
        .input-group input { width: 100%; padding: 12px; border: 1px solid #e0e0e0; border-radius: 8px; box-sizing: border-box; font-size: 15px; }
        /* 新增不可编辑输入框样式，视觉上区分 */
        .input-group input[disabled] { background-color: #f5f5f5; color: #666; cursor: not-allowed; }
        .btn-query { width: 100%; background: var(--primary); color: white; border: none; padding: 14px; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; }
        
        /* 左侧概况样式 */
        .official-header { border-left: 5px solid var(--primary); padding-left: 15px; line-height: 1.8; }
        .info-row { display: flex; justify-content: flex-start; margin-bottom: 4px; border-bottom: 1px dashed #f0f0f0; padding-bottom: 4px; }
        .info-label { width: 90px; color: var(--text-sub); flex-shrink: 0; }
        .info-val { font-weight: 500; }
        .price-highlight { color: var(--accent); font-weight: bold; }
        .trend-box { background: #fafafa; border-radius: 8px; padding: 10px; margin-top: 10px; font-size: 13px; border: 1px solid #f0f0f0;}
        .trend-title { font-weight: bold; color: var(--primary); margin-bottom: 5px; font-size: 12px; border-bottom: 1px solid #e8e8e8; padding-bottom: 4px;}

        /* 右侧订购业务样式：单行化 */
        .item-l1 { background: #fff; margin-top: 10px; border-radius: 8px; border: 1px solid #eee; overflow: hidden; }
        .item-l1-head { background: var(--secondary); padding: 12px 15px; border-bottom: 1px solid #e0eaff; }
        .sub-items { padding-left: 20px; }
        .item-l2, .item-l3 { padding: 10px 15px; border-bottom: 1px solid #f9f9f9; position: relative; }
        .item-l2::before { content: ""; position: absolute; left: 0; top: 0; bottom: 0; width: 2px; background: #d0e4ff; }
        .item-l3 { padding-left: 30px; }
        .item-l3::before { content: ""; position: absolute; left: 0; top: 0; bottom: 0; width: 2px; background: #e0e0e0; }
        
        .item-main-line { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; line-height: 1.4; }
        .tag { font-size: 11px; padding: 1px 6px; border-radius: 4px; }
        .tag-active { background: #e6ffed; color: #28a745; border: 1px solid #b7eb8f; }
        .tag-pending { background: #fff7e6; color: #fa8c16; border: 1px solid #ffd591; }
        
        .price-tag { color: var(--accent); font-weight: bold; font-size: 14px; }
        .price-free { color: #aaa; font-size: 12px; }
        
        /* 有效期后置：字体减小，颜色淡化 */
        .effect-time-inline { font-size: 12px; color: #888; font-weight: normal; }

        /* 气泡告警样式 */
        #toast { 
            position: fixed; top: 20px; left: 50%; transform: translateX(-50%); 
            background: rgba(0,0,0,0.8); color: #fff; padding: 12px 24px; 
            border-radius: 50px; z-index: 1000; display: none; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.2); font-size: 14px;
        }

        #loading { display: none; text-align: center; padding: 30px; color: var(--primary); }
        .spinning { display: inline-block; width: 20px; height: 20px; border: 3px solid rgba(0,133,208,0.3); border-top-color: var(--primary); border-radius: 50%; animation: spin 1s linear infinite; vertical-align: middle; }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>

<div id="toast"></div>

<div class="container">
    <div class="left-panel">
        <div class="card">
            <div class="search-title">业务综合查询</div>
            <div class="input-group">
                <label>API TOKEN</label>
                <!-- 增加disabled属性设置不可编辑，value从ASP变量获取 -->
                <input type="text" id="token" value="<%=Server.HTMLEncode(tokenFromUrl)%>" disabled>
            </div>
            <div class="input-group">
                <label>号码</label>
                <input type="text" id="phone" value="">
            </div>
            <button class="btn-query" onclick="doQuery()">查询</button>
        </div>
        <div id="loading"><span class="spinning"></span> 正在查询中...</div>
        <div id="resultLeft" style="display:none;">
            <div class="card">
                <div class="official-header" id="officialHeader"></div>
            </div>
        </div>
    </div>

    <div class="right-panel">
        <div id="resultRight" style="display:none;">
            <div class="card" style="min-height: 500px;">
                <div id="productList"></div>
            </div>
        </div>
    </div>
</div>

<script>
// 气泡提示函数
function showToast(msg) {
    const toast = document.getElementById('toast');
    toast.innerText = msg;
    toast.style.display = 'block';
    setTimeout(() => { toast.style.display = 'none'; }, 3000);
}

function formatDate(ts) {
    const d = new Date(parseInt(ts));
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`;
}

async function doQuery() {
    const token = document.getElementById('token').value;
    const phone = document.getElementById('phone').value;
    const loading = document.getElementById('loading');
    const resultLeft = document.getElementById('resultLeft');
    const resultRight = document.getElementById('resultRight');
    
    if(!token || !phone) return showToast('请输入完整的Token和手机号');
    
    loading.style.display = 'block';
    resultLeft.style.display = 'none';
    resultRight.style.display = 'none';

    try {
        const response = await fetch(`http://8.134.38.66:9125/api/pc/ngboss/queryOverall/${phone}?token=${token}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'token': token },
            body: JSON.stringify({})
        });
        const res = await response.json();
        if(res.status === 0) render(res.data); 
        else showToast('查询失败：' + (res.message || '接口异常'));
    } catch (e) { 
        showToast('请求异常，请检查网络或Token');
    } finally { 
        loading.style.display = 'none'; 
    }
}

function render(data) {
    // 渲染左侧... (保持之前的高级排序逻辑)
    const headerHtml = `
        <div style="font-size:16px; font-weight:bold; color:var(--primary); margin-bottom:12px;">客户基本概况</div>
        <div class="info-row"><span class="info-label">客户名称：</span><span class="info-val">${data.name}</span></div>
        <div class="info-row"><span class="info-label">号码状态：</span><span class="info-val" style="color:#28a745">● ${data.currentStatus}</span></div>
        <div class="info-row" style="margin-top:10px"><span class="info-label">可用余额：</span><span class="info-val price-highlight">${data.balance} 元</span></div>
        <div class="info-row"><span class="info-label">用户品牌：</span><span class="info-val">${data.userBrand}</span></div>
        <div class="info-row"><span class="info-label">月结日：</span><span class="info-val">${data.settleDay} 号</span></div>
        <div class="info-row"><span class="info-label">入网日期：</span><span class="info-val">${formatDate(data.createDate)}</span></div>
        
        <div class="trend-box">
            <div class="trend-title">近三月流量/消费</div>
            ${data.flowInfo[1].monthTotal}G / ￥${(data.consumeInfo[1].bqfyze/100).toFixed(2)}<br>
            ${data.flowInfo[2].monthTotal}G / ￥${(data.consumeInfo[2].bqfyze/100).toFixed(2)}<br>
            ${data.flowInfo[0].monthTotal}G / ￥${(data.consumeInfo[0].bqfyze/100).toFixed(2)}
        </div>
    `;
    document.getElementById('officialHeader').innerHTML = headerHtml;

    // 排序逻辑 (家族权重排序)
    const allItems = data.productList;
    const tree = allItems.filter(i => i.level === 1).map(l1 => {
        const childrenL2 = allItems.filter(i => i.level === 2 && i.packageProdID === l1.oid).map(l2 => {
            const childrenL3 = allItems.filter(i => i.level === 3 && i.packageProdID === l2.oid);
            const maxPriceL2 = Math.max(l2.price || 0, ...childrenL3.map(l3 => l3.price || 0));
            return { ...l2, children: childrenL3, maxPrice: maxPriceL2 };
        });
        childrenL2.sort((a, b) => b.maxPrice - a.maxPrice);
        const maxPriceL1 = Math.max(l1.price || 0, ...childrenL2.map(l2 => l2.maxPrice));
        return { ...l1, children: childrenL2, maxPrice: maxPriceL1 };
    });
    tree.sort((a, b) => b.maxPrice - a.maxPrice);

    // 渲染右侧 (有效期后置到业务名后面)
    const listDiv = document.getElementById('productList');
    listDiv.innerHTML = '<div style="margin: 5px 0 15px; font-size:16px; font-weight:bold; color:var(--primary); border-bottom: 2px solid var(--primary); padding-bottom: 10px; display:inline-block;">订购业务详情</div>';
    
    tree.forEach(l1 => {
        const itemHtml = (item) => {
            const tagClass = item.status === '生效' ? 'tag-active' : 'tag-pending';
            const priceStr = item.price > 0 ? `<span class="price-tag">￥${item.price}</span>` : `<span class="price-free"></span>`;
            return `
                <div class="item-main-line">
                    <strong>${item.title}</strong>
                    <span class="tag ${tagClass}">${item.status}</span>
                    ${priceStr}
                    <span class="effect-time-inline">(${item.effectiveTime})</span>
                </div>
            `;
        };

        const l1Node = document.createElement('div');
        l1Node.className = 'item-l1';
        l1Node.innerHTML = `<div class="item-l1-head">${itemHtml(l1)}</div><div class="sub-items"></div>`;
        listDiv.appendChild(l1Node);

        l1.children.forEach(l2 => {
            const l2Node = document.createElement('div');
            l2Node.className = 'item-l2';
            l2Node.innerHTML = itemHtml(l2) + `<div class="sub-items-l3"></div>`;
            l1Node.querySelector('.sub-items').appendChild(l2Node);

            l2.children.sort((a, b) => b.price - a.price).forEach(l3 => {
                const l3Node = document.createElement('div');
                l3Node.className = 'item-l3';
                l3Node.innerHTML = itemHtml(l3);
                l2Node.querySelector('.sub-items-l3').appendChild(l3Node);
            });
        });
    });

    document.getElementById('resultLeft').style.display = 'block';
    document.getElementById('resultRight').style.display = 'block';
}
</script>
</body>
</html>