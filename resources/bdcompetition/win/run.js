// ==UserScript==
// @name         Search on LocalDB
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       yiluohan1234
// @match        https://www.qingjiaoclass.com/*
// @connect      127.0.0.1
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function() {
    'use strict';

    var container = container || document;
    container.onmouseup = function(event){
        var txt = getSelectText();
        if(txt){
            getAnswer(txt).then(res => {
                console.log(res);
                event.target.innerHTML =event.target.innerHTML.replace(txt, txt+res);
            });
            //event.target.innerHTML =event.target.innerHTML.replace(txt, '<span style="background-color:yellow">'+txt+'</span>');
        }
    }

    /**
	 * 获取选中的文字
	 */
    function getSelectText(){
        var txt = window.getSelection?window.getSelection():document.selection.createRange().text;
        return txt.toString();
    }

    /**
	 * 获取答案
	 * @param title 题目内容
	 */
    function getAnswer(title) {
        return new Promise(resolve => {
            GM_xmlhttpRequest({
                url: 'http://127.0.0.1:8000/data/',
                method: 'POST',
                data: JSON.stringify({'title': title}),
                headers: {"Content-Type": "application/json"},
                dataType: "json",
                async: true,
                onload: function (res) {
                    let json = JSON.parse(res.response);
                    if (json.code === 200) {
                        console.log("request success!\nresult:", json.data)
                        resolve(json.data[0].answer+json.data.length)
                    } else {
                        console.log("request failed!\nmsg:", json.msg)
                    }
                }, onerror: function (err) {
                    console.log("request error", err)
                }
            })
        })
    }
})();
