/**
 * Custom Light Theme Modal System
 * Overrides window.alert and window.confirm with light-themed Tailwind modals.
 */

(function() {
    // Force light color scheme for browser elements
    const meta = document.createElement('meta');
    meta.name = "color-scheme";
    meta.content = "light";
    document.head.appendChild(meta);

    // Create Modal Structure
    const modalHtml = `
    <div id="custom-modal-container" class="fixed inset-0 z-[9999] hidden flex items-center justify-center bg-black/40 backdrop-blur-sm transition-opacity duration-300">
        <div id="custom-modal" class="bg-white rounded-[2rem] shadow-2xl w-[90%] max-w-sm p-8 transform scale-95 transition-all duration-300 opacity-0">
            <h3 id="modal-title" class="text-xl font-extrabold text-[#111827] mb-3 text-center"></h3>
            <p id="modal-message" class="text-[#64748b] text-base font-medium mb-8 text-center leading-relaxed"></p>
            <div id="modal-actions" class="flex flex-col gap-3">
                <button id="modal-confirm" class="w-full bg-[#7C3AED] hover:bg-[#6D28D9] text-white font-black py-4 rounded-2xl shadow-lg shadow-purple-200 active:scale-[0.98] transition-all">
                    Tamam
                </button>
                <button id="modal-cancel" class="w-full bg-gray-50 hover:bg-gray-100 text-[#1e293b] font-bold py-4 rounded-2xl active:scale-[0.98] transition-all hidden">
                    Vazgeç
                </button>
            </div>
        </div>
    </div>`;

    document.body.insertAdjacentHTML('beforeend', modalHtml);

    const container = document.getElementById('custom-modal-container');
    const modal = document.getElementById('custom-modal');
    const titleEl = document.getElementById('modal-title');
    const messageEl = document.getElementById('modal-message');
    const confirmBtn = document.getElementById('modal-confirm');
    const cancelBtn = document.getElementById('modal-cancel');

    let resolveFn = null;

    function showModal(title, message, isConfirm = false) {
        titleEl.textContent = title || "Bilgi";
        messageEl.textContent = message;
        cancelBtn.classList.toggle('hidden', !isConfirm);
        
        container.classList.remove('hidden');
        setTimeout(() => {
            modal.classList.remove('scale-95', 'opacity-0');
            modal.classList.add('scale-100', 'opacity-100');
        }, 10);

        return new Promise((resolve) => {
            resolveFn = resolve;
        });
    }

    function hideModal(value) {
        modal.classList.add('scale-95', 'opacity-0');
        modal.classList.remove('scale-100', 'opacity-100');
        setTimeout(() => {
            container.classList.add('hidden');
            if (resolveFn) resolveFn(value);
        }, 300);
    }

    confirmBtn.onclick = () => hideModal(true);
    cancelBtn.onclick = () => hideModal(false);

    // Override Alert
    window.alert = function(message) {
        return showModal("Bilgilendirme", message, false);
    };

    // Override Confirm
    // Note: Native confirm is synchronous, but custom is async.
    // For simple cases, we recommend using the async version directly,
    // but we can try to wrap logic if needed. 
    // However, the best practice is to call a custom function.
    window.customConfirm = function(title, message) {
        return showModal(title, message, true);
    };
})();
