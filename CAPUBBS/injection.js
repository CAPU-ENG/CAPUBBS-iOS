(() => {
    // Click to open images
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
            window.webkit.messageHandlers.imageClickHandler.postMessage({
                loading: true
            });
            fetch(imgSrc)
                .then((response) => response.blob())
                .then((blob) => {
                    const reader = new FileReader();
                    reader.onloadend = () => {
                        const base64data = reader.result;
                        window.webkit.messageHandlers.imageClickHandler.postMessage({
                            loading: false,
                            src: imgSrc,
                            data: base64data
                        });
                    };
                    reader.readAsDataURL(blob);
                })
                .catch((error) => {
                    window.webkit.messageHandlers.imageLoadingHandler.postMessage({
                        loading: false
                    });
                    console.error('Image fetch error:', error);
                });
        }
    }, true);
    
    // Show / hide images
    const styleId = '_hide_images_style_';
    const hiddenClass = 'image-blocked';

    const createCSS = () => {
        if (document.getElementById(styleId)) {
            return;
        }
        const style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
            img.${hiddenClass} {
                display: block !important;
                background-color: #f0f0f0 !important;
                border: 1px solid #ccc !important;
            }
        `;
        document.head.appendChild(style);
    }

    const hideImage = (img) => {
        if (img.dataset._originalSrc || !img.src) {
            return;
        }

        img.dataset._originalSrc = img.src;
        img.removeAttribute('src');
        img.alt = '🚫';
        img.classList.add(hiddenClass);
    }

    const restoreImage = (img) => {
        if (!img.dataset._originalSrc) {
            return;
        }

        img.src = img.dataset._originalSrc;
        delete img.dataset._originalSrc;
        img.classList.remove(hiddenClass);
    }

    window.hideAllImages = (shouldHide) => {
        if (window._hideAllImages === shouldHide) {
            return;
        }
        window._hideAllImages = shouldHide;

        if (shouldHide) {
            createCSS();
            document.querySelectorAll('img').forEach(hideImage);
        } else {
            document.querySelectorAll('img').forEach(restoreImage);
        }
    };

    const observer = new MutationObserver(mutations => {
        if (!window._hideAllImages) {
            return;
        }
        
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

window.hideAllImages(window._hideAllImages);
