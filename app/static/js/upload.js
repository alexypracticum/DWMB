/**
 * File upload utility with type filtering and gallery support.
 */

const UPLOAD_FILTERS = {
    image: { accept: 'image/jpeg,image/png,image/webp,image/gif,image/svg+xml' },
    gallery: { accept: 'image/jpeg,image/png,image/webp,image/gif,image/svg+xml' },
    video: { accept: 'video/mp4,video/webm,video/ogg' },
    audio: { accept: 'audio/mpeg,audio/ogg,audio/wav,audio/webm' },
    file: { accept: '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.csv,.json,.xml,.zip,.rar,.7z' },
    any: { accept: '' },
};

function triggerUpload(btn, filterType) {
    const row = btn.closest('.flex.items-center');
    if (!row) return;
    const input = row.querySelector('input[type="text"], textarea');
    if (!input) return;

    const filter = UPLOAD_FILTERS[filterType] || UPLOAD_FILTERS.any;
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.accept = filter.accept;
    fileInput.style.display = 'none';

    fileInput.addEventListener('change', async function() {
        const file = this.files[0];
        if (!file) return;

        const btnHTML = btn.innerHTML;
        btn.innerHTML = '⏳';
        btn.disabled = true;

        const formData = new FormData();
        formData.append('file', file);

        try {
            const resp = await fetch('/upload', { method: 'POST', body: formData });
            const data = await resp.json();

            if (resp.ok && data.url) {
                input.value = data.url;
                input.dispatchEvent(new Event('change'));
                showToast('Загружен: ' + file.name, 'success');
            } else {
                showToast(data.error || 'Ошибка загрузки', 'error');
            }
        } catch (e) {
            showToast('Ошибка сети', 'error');
        } finally {
            btn.innerHTML = btnHTML;
            btn.disabled = false;
            fileInput.remove();
        }
    });

    document.body.appendChild(fileInput);
    fileInput.click();
}

function triggerGalleryUpload(btn, textareaName) {
    const filter = UPLOAD_FILTERS.gallery;
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.accept = filter.accept;
    fileInput.multiple = true;
    fileInput.style.display = 'none';

    fileInput.addEventListener('change', async function() {
        const files = this.files;
        if (!files.length) return;

        const btnHTML = btn.innerHTML;
        btn.innerHTML = '⏳ Загрузка...';
        btn.disabled = true;

        // Find textarea by name
        const textarea = document.querySelector('textarea[name="' + textareaName + '"]');
        if (!textarea) { btn.innerHTML = btnHTML; btn.disabled = false; fileInput.remove(); return; }

        let uploaded = 0;
        for (const file of files) {
            const formData = new FormData();
            formData.append('file', file);
            try {
                const resp = await fetch('/upload', { method: 'POST', body: formData });
                const data = await resp.json();
                if (resp.ok && data.url) {
                    const current = textarea.value.trim();
                    textarea.value = current ? current + '\n' + data.url : data.url;
                    uploaded++;
                }
            } catch (e) { /* skip */ }
        }

        textarea.dispatchEvent(new Event('change'));
        btn.innerHTML = btnHTML;
        btn.disabled = false;
        fileInput.remove();
        showToast('Загружено: ' + uploaded + ' из ' + files.length, uploaded === files.length ? 'success' : 'error');
    });

    document.body.appendChild(fileInput);
    fileInput.click();
}

function clearGallery(btn, textareaName) {
    const textarea = document.querySelector('textarea[name="' + textareaName + '"]');
    if (textarea) textarea.value = '';
}

function showToast(msg, type) {
    const existing = document.getElementById('upload-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'upload-toast';
    toast.style.cssText = 'position:fixed;bottom:1rem;right:1rem;z-index:9999;padding:0.75rem 1rem;border-radius:0.5rem;box-shadow:0 4px 12px rgba(0,0,0,0.15);font-size:0.875rem;transition:opacity 0.3s;';
    toast.style.background = type === 'success' ? '#16a34a' : '#dc2626';
    toast.style.color = '#fff';
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}
