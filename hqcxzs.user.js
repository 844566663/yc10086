// ==UserScript==
// @name         华启查询助手
// @namespace
// @version      2.5
// @description
// @author
// @match        http://tongyun.hqcmcc.com:18999/*
// @grant        GM_xmlhttpRequest
// @grant        GM_addStyle
// @run-at       document-end
// @updateURL    https://cdn.jsdelivr.net/gh/844566663/yc10086@main/hqcxzs.user.js
// @downloadURL  https://cdn.jsdelivr.net/gh/844566663/yc10086@main/hqcxzs.user.js
// ==/UserScript==

(function() {
    'use strict';

    const CONFIG = {
        keywordUrl: 'https://cdn.jsdelivr.net/gh/844566663/yc10086@main/fshuchi.html',
        checkInterval: 1000,
        refreshKeywordInterval: 60000,
        retryDelay: 1000,
        maxRetryCount: 50,
        retryFinishDelay: 1000,
        targetPageUrl: 'http://tongyun.hqcmcc.com:18999/biz/taskSinglePhoneQuery'
    };

    let keywordList = [];
    let lastMatchStr = "";
    let lastUpdateTime = "";
    let retryCount = 0;
    let enableAuto = true;
    let isRetrying = false;
    let blockPopup = false;
    let retryTimer = null;
    let pendingRetry = false;
    let isPageVisible = true; // 页面是否可见标记

    // 监听页面可见性变化（切走/切回）
    document.addEventListener('visibilitychange', () => {
        isPageVisible = !document.hidden;
        // 页面不可见时，立即停止所有重试
        if (!isPageVisible) {
            stopAllRetry();
            console.log('页面已隐藏，停止自动重试');
        } else {
            console.log('页面已激活，恢复自动查询');
        }
    });

    GM_addStyle(`
        .mutex-highlight {
            background:#fff2f2 !important;
            color:#d93025 !important;
            font-weight:bold !important;
            padding:2px 4px !important;
            border-radius:3px !important;
            border:1px solid #ffcccc !important;
        }
        .mutex-modal-overlay{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;z-index:999999;}
        .mutex-modal-box{background:#fff;width:90%;max-width:420px;border-radius:12px;padding:24px;box-shadow:0 10px 30px rgba(0,0,0,0.2);text-align:center;}
        .mutex-modal-icon{width:50px;height:50;background:#fff2f2;color:#f53f3f;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;margin:0 auto 16px;}
        .mutex-modal-title{font-size:18px;font-weight:bold;color:#333;margin-bottom:12px;}
        .mutex-modal-content{font-size:15px;color:#666;line-height:1.6;margin-bottom:24px;}
        .mutex-modal-close{background:#0085d0;color:#fff;border:none;padding:10px 24px;border-radius:8px;font-size:15px;cursor:pointer;}
        #mutexFooterTip {
            position: fixed;
            left: 10px;
            bottom: 10px;
            background: rgba(0,0,0,0.65);
            color: #fff;
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            z-index: 99999;
            pointer-events: none;
        }
        #stopRetryBtn {
            margin-left: 10px;
            height: 32px;
            padding: 0 15px;
            border-radius: 6px;
            border: 1px solid #ff4d4f;
            background: #fff2f2;
            color: #ff4d4f;
            cursor: pointer;
            font-size: 14px;
        }
        #checkMutexBtn {
            margin-left: 10px;
            height: 32px;
            padding: 0 15px;
            border-radius: 6px;
            border: 1px solid #1890ff;
            background: #e6f7ff;
            color: #1890ff;
            cursor: pointer;
            font-size: 14px;
        }
    `);

    function isTargetPage() {
        return window.location.href.startsWith(CONFIG.targetPageUrl);
    }

    function createFooterTip() {
        let tip = document.getElementById('mutexFooterTip');
        if (!tip) {
            tip = document.createElement('div');
            tip.id = 'mutexFooterTip';
            document.body.appendChild(tip);
        }
        return tip;
    }

    function updateFooterText() {
        const tip = createFooterTip();
        const count = keywordList.length;
        const stopText = !enableAuto ? '｜[已停止]' : '';
        const pageStatus = !isPageVisible ? '｜[已隐藏]' : '';
        tip.innerText = `互斥项目表｜最后更新:${lastUpdateTime}｜共${count}个关键词｜重试:${retryCount}/${CONFIG.maxRetryCount}${stopText}${pageStatus}`;
    }

    function formatTime(date) {
        const h = String(date.getHours()).padStart(2,'0');
        const m = String(date.getMinutes()).padStart(2,'0');
        const s = String(date.getSeconds()).padStart(2,'0');
        return `${h}:${m}:${s}`;
    }

    // 加载关键词：失败时不清空原有列表
    function loadKeywordList() {
        GM_xmlhttpRequest({
            method: "GET",
            url: CONFIG.keywordUrl + "?t=" + Date.now(),
            timeout: 8000,
            onload: res => {
                if(res.status === 200){
                    keywordList = res.responseText
                        .split("\n")
                        .map(s => s.trim())
                        .filter(s => s);
                    lastUpdateTime = formatTime(new Date());
                } else {
                    // 请求失败，保留旧数据，只更新时间提示
                    lastUpdateTime = `更新失败(${res.status})`;
                }
                updateFooterText();
            },
            onerror: () => {
                // 网络错误，保留旧数据
                lastUpdateTime = "网络异常";
                updateFooterText();
            }
        });
    }

    function clearHighlight() {
        document.querySelectorAll(".mutex-highlight").forEach(el => {
            el.outerHTML = el.innerHTML;
        });
    }

    function showMutexTip(words) {
        if(blockPopup || isRetrying) return;
        if(document.querySelector(".mutex-modal-overlay")) return;
        const overlay = document.createElement("div");
        overlay.className = "mutex-modal-overlay";
        overlay.innerHTML = `
            <div class="mutex-modal-box">
                <div class="mutex-modal-icon">!</div>
                <div class="mutex-modal-title">可能导致办理失败的互斥项目</div>
                <div class="mutex-modal-content">
                    检测到互斥项目：<br>${words.map(w => "• " + w).join("<br>")}
                </div>
                <button class="mutex-modal-close">我知道了</button>
            </div>`;
        document.body.appendChild(overlay);
        overlay.querySelector(".mutex-modal-close").onclick = () => overlay.remove();
    }

    function showNoMutexTip() {
        if(document.querySelector(".mutex-modal-overlay")) return;
        const overlay = document.createElement("div");
        overlay.className = "mutex-modal-overlay";
        overlay.innerHTML = `
            <div class="mutex-modal-box">
                <div class="mutex-modal-icon" style="background:#f6ffed;color:#52c41a;">✓</div>
                <div class="mutex-modal-title">检测完成</div>
                <div class="mutex-modal-content">
                    没有检测到互斥项目，如果仍然办理失败，请反馈到项目群
                </div>
                <button class="mutex-modal-close">确定</button>
            </div>`;
        document.body.appendChild(overlay);
        overlay.querySelector(".mutex-modal-close").onclick = () => overlay.remove();
    }

    function scanAndHighlight(showResult = true) {
        if(isRetrying || blockPopup || !keywordList.length) return;
        clearHighlight();
        const matched = new Set();
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
        let node;
        while(node = walker.nextNode()){
            const p = node.parentElement;
            if(!p || ["SCRIPT","STYLE"].includes(p.tagName) || p.closest(".mutex-modal-overlay")) continue;
            let txt = node.textContent;
            keywordList.forEach(kw => {
                if(txt.includes(kw)){
                    matched.add(kw);
                    let reg = new RegExp("(" + kw.replace(/[.*+?^${}()|[\]\\]/g,"\\$&") + ")","g");
                    txt = txt.replace(reg,'<span class="mutex-highlight">$1</span>');
                }
            });
            if(txt !== node.textContent){
                let sp = document.createElement("span");
                sp.innerHTML = txt;
                node.parentNode.replaceChild(sp, node);
            }
        }
        const nowMatchStr = Array.from(matched).join("|");
        const hasMatch = matched.size > 0;
        if (showResult) {
            if (hasMatch) {
                lastMatchStr = nowMatchStr;
                showMutexTip(Array.from(matched));
            } else {
                lastMatchStr = "";
                showNoMutexTip();
            }
        }
    }

    function addStopBtn() {
        if(!isTargetPage()) return;
        if(document.getElementById("stopRetryBtn")) return;
        const queryBtn = document.querySelector('button.ant-btn-primary');
        if(!queryBtn) return;
        let btn = document.createElement("button");
        btn.id = "stopRetryBtn";
        btn.innerText = "停止查询";
        queryBtn.after(btn);
        btn.onclick = () => {
            stopAllRetry();
            enableAuto = false;
            updateFooterText();
        };
    }

    function addCheckMutexBtn() {
        if(!isTargetPage()) return;
        if(document.getElementById("checkMutexBtn")) return;
        const stopBtn = document.getElementById("stopRetryBtn");
        if(!stopBtn) return;
        let btn = document.createElement("button");
        btn.id = "checkMutexBtn";
        btn.innerText = "检测互斥";
        stopBtn.after(btn);
        btn.onclick = () => {
            scanAndHighlight(true);
        };
    }

    function stopAllRetry() {
        if(retryTimer) clearTimeout(retryTimer);
        retryTimer = null;
        isRetrying = false;
        blockPopup = false;
        pendingRetry = false;
    }

    function finishRetry(){
        stopAllRetry();
        setTimeout(()=>{
            scanAndHighlight(false);
        }, CONFIG.retryFinishDelay);
    }

    // 真正延迟执行重试，杜绝秒点 + 页面不可见时不执行
    function startDelayRetry() {
        // 页面不可见时直接不执行重试
        if (!enableAuto || isRetrying || pendingRetry || !isPageVisible) return;

        if(retryCount >= CONFIG.maxRetryCount){
            finishRetry();
            return;
        }
        pendingRetry = true;
        retryTimer = setTimeout(() => {
            pendingRetry = false;
            isRetrying = true;
            blockPopup = true;
            retryCount++;
            updateFooterText();
            const btn = document.querySelector('button.ant-btn-primary');
            if(btn) {
                btn.dispatchEvent(new Event('click', { bubbles: true }));
            }
            // 点击后释放锁定
            setTimeout(()=>{
                isRetrying = false;
            }, 300);
        }, CONFIG.retryDelay);
    }

    // 500错误只触发延迟重试，不再立即点击
    function watch500Error() {
        window.addEventListener('unhandledrejection', e => {
            const res = e.reason;
            if(!enableAuto) return;
            if(res && res.code === 500){
                startDelayRetry();
            }
        });
    }

    function bindManualQuery() {
        document.addEventListener("click", e => {
            if(e.target.closest('button.ant-btn-primary')){
                stopAllRetry();
                retryCount = 0;
                enableAuto = true;
                updateFooterText();
            }
        });
    }

    function init(){
        createFooterTip();
        loadKeywordList();
        setInterval(loadKeywordList, CONFIG.refreshKeywordInterval);
        setInterval(addStopBtn, 1000);
        setInterval(addCheckMutexBtn, 1000);
        watch500Error();
        bindManualQuery();
        updateFooterText();
    }

    if(document.readyState === "complete") init();
    else window.addEventListener("load", init);
})();
