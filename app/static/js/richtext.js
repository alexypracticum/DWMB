/**
 * TipTap WYSIWYG editor initialization.
 * Usage: <div id="editor" data-field="field_name"></div>
 *        <input type="hidden" name="field_name" id="field_name_input">
 */
function initTipTapEditor(containerId, hiddenInputId) {
    const container = document.getElementById(containerId);
    if (!container) return null;

    const { Editor } = window.Tiptap;
    const { StarterKit } = window.TiptapStarterKit;
    const { Link } = window.TiptapLink;
    const { Image } = window.TiptapImage;

    // Create toolbar
    const toolbar = document.createElement('div');
    toolbar.className = 'tiptap-toolbar';
    toolbar.style.cssText = 'display:flex;gap:4px;padding:8px;border-bottom:1px solid var(--color-border);flex-wrap:wrap;';

    const buttons = [
        { label: 'B', command: 'toggleBold', title: 'Жирный' },
        { label: 'I', command: 'toggleItalic', title: 'Курсив' },
        { label: 'S', command: 'toggleStrike', title: 'Зачёркнутый' },
        { label: 'H1', command: 'toggleHeading', args: { level: 1 }, title: 'Заголовок 1' },
        { label: 'H2', command: 'toggleHeading', args: { level: 2 }, title: 'Заголовок 2' },
        { label: 'H3', command: 'toggleHeading', args: { level: 3 }, title: 'Заголовок 3' },
        { label: '•', command: 'toggleBulletList', title: 'Маркированный список' },
        { label: '1.', command: 'toggleOrderedList', title: 'Нумерованный список' },
        { label: '""', command: 'toggleBlockquote', title: 'Цитата' },
        { label: '—', command: 'setHorizontalRule', title: 'Разделитель' },
        { label: '🔗', command: 'setLink', title: 'Ссылка' },
        { label: '↩', command: 'undo', title: 'Отменить' },
        { label: '↪', command: 'redo', title: 'Повторить' },
    ];

    buttons.forEach(btn => {
        const button = document.createElement('button');
        button.type = 'button';
        button.textContent = btn.label;
        button.title = btn.title;
        button.className = 'px-2 py-1 text-xs rounded transition';
        button.style.cssText = 'background:var(--color-bg);border:1px solid var(--color-border);color:var(--color-text);';
        button.addEventListener('mousedown', (e) => {
            e.preventDefault();
            if (btn.command === 'setLink') {
                const url = prompt('URL ссылки:');
                if (url) {
                    editor.chain().focus().setLink({ href: url }).run();
                }
            } else if (btn.args) {
                editor.chain().focus()[btn.command](btn.args).run();
            } else {
                editor.chain().focus()[btn.command]().run();
            }
        });
        toolbar.appendChild(button);
    });

    container.insertBefore(toolbar, container.firstChild);

    // Create editor
    const hiddenInput = document.getElementById(hiddenInputId);
    const initialContent = hiddenInput ? hiddenInput.value : '';

    const editor = new Editor({
        element: container,
        extensions: [
            StarterKit,
            Link.configure({ openOnClick: false }),
            Image,
        ],
        content: initialContent,
        onUpdate: ({ editor }) => {
            if (hiddenInput) {
                hiddenInput.value = editor.getHTML();
            }
        },
    });

    // Sync initial content
    if (hiddenInput) {
        hiddenInput.value = editor.getHTML();
    }

    return editor;
}

// Auto-initialize all editors on page
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-tiptap]').forEach(el => {
        const field = el.dataset.field || el.id;
        initTipTapEditor(el.id, field + '_input');
    });
});
