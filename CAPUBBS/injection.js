// Click to open images
(() => {
    document.addEventListener('click', (event) => {
        const target = event.target;
        if (target.tagName.toLowerCase() === 'img') {
            if (!window._imageClickHandlerAvailable) {
                return;
            }
            const imgSrc = target.src || target.dataset._originalSrc;
            if (!imgSrc) {
                return;
            }
            event.preventDefault();
            
            // Add a very short delay in case the load is very fast so we don't need to show loading hud
            const sendLoadingSignal = setTimeout(() => {
                window.webkit.messageHandlers.imageClickHandler.postMessage({
                    loading: true
                });
            }, 50);
            
            const options = {};
            let timeoutId;
            if (typeof AbortController === 'function') {
                const controller = new AbortController();
                options.signal = controller.signal;
                timeoutId = setTimeout(() => controller.abort(), 10 * 1000); // 10s
            }
            fetch(imgSrc, options)
            .then((response) => {
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status} 错误`);
                }
                return response.blob();
            })
            .then((blob) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64data = reader.result;
                    clearTimeout(sendLoadingSignal);
                    window.webkit.messageHandlers.imageClickHandler.postMessage({
                        loading: false,
                        src: imgSrc,
                        data: base64data,
                        alt: target.alt || ''
                    });
                };
                reader.onerror = () => {
                    clearTimeout(sendLoadingSignal);
                    window.webkit.messageHandlers.imageClickHandler.postMessage({
                        loading: false,
                        src: imgSrc,
                        error: reader.error?.message || '图片格式错误',
                    });
                };
                reader.readAsDataURL(blob);
            })
            .catch((error) => {
                let message = error.message || '未知错误';
                if (error.name === 'AbortError') {
                    message = '图片加载超时'
                } else if (message.includes('Failed to fetch')) {
                    message = '网络连接失败';
                }
                clearTimeout(sendLoadingSignal);
                window.webkit.messageHandlers.imageClickHandler.postMessage({
                    loading: false,
                    src: imgSrc,
                    error: message,
                });
            })
            .finally(() => {
                if (timeoutId) {
                    clearTimeout(timeoutId);
                }
            });
        }
    }, true);
})();

// Show / hide images
(() => {
    if (!window._hideAllImages) {
        return;
    }
    const hideImage = (img) => {
        if (img.dataset._originalSrc || !img.src) {
            return;
        }

        img.dataset._originalSrc = img.src;
        img.removeAttribute('src');
        img.alt = '🚫';
        img.classList.add('image-hidden');
    }
    
    document.querySelectorAll('img').forEach(hideImage);

    const observer = new MutationObserver((mutations) => {
        mutations.forEach((m) => {
            m.addedNodes.forEach((node) => {
                if (node.tagName === 'IMG') {
                    hideImage(node);
                } else if (node.querySelectorAll) {
                    node.querySelectorAll('img').forEach(hideImage);
                }
            });
        });
    });
    observer.observe(document.body, { childList: true, subtree: true });
})();
