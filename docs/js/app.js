// MyBSD Tomoyo Explorer Landing Page JavaScript

document.addEventListener('DOMContentLoaded', () => {
  // 1-Liner Clipboard Copy
  const copyBtn = document.getElementById('copyInstallBtn');
  const installCmd = document.getElementById('installCmdText');

  if (copyBtn && installCmd) {
    copyBtn.addEventListener('click', async () => {
      const textToCopy = installCmd.innerText.trim();
      try {
        await navigator.clipboard.writeText(textToCopy);
        copyBtn.classList.add('copied');
        copyBtn.innerHTML = `
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
          Copied!
        `;
        setTimeout(() => {
          copyBtn.classList.remove('copied');
          copyBtn.innerHTML = `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
            </svg>
            Copy
          `;
        }, 2500);
      } catch (err) {
        console.error('Failed to copy: ', err);
      }
    });
  }

  // Platform Tabs Switcher
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabContents = document.querySelectorAll('.tab-content');

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetPlatform = btn.getAttribute('data-tab');

      tabBtns.forEach(b => b.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const activeContent = document.getElementById(`tab-${targetPlatform}`);
      if (activeContent) {
        activeContent.classList.add('active');
      }
    });
  });
});
