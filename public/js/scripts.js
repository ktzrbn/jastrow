// public/js/scripts.js
document.addEventListener('DOMContentLoaded', () => {
  console.log('Script loaded');
  const searchBar = document.getElementById('search-bar');
  const keyboard = document.getElementById('hebrew-keyboard');
  const closeButton = document.getElementById('close-keyboard');
  const dragHandle = document.getElementById('keyboard-drag-handle');
  const keys = document.querySelectorAll('.key');

  // Initial hide
  keyboard.style.display = 'none';

  // Function to check if on mobile
  const isMobile = () => window.innerWidth <= 768;

  // Show keyboard on focus and position it (only on desktop)
  searchBar.addEventListener('focus', () => {
    if (!isMobile()) {
      keyboard.style.display = 'block';
      positionKeyboard();
    }
  });

  // Hide keyboard on close
  closeButton.addEventListener('click', () => {
    keyboard.style.display = 'none';
  });

  // Hide keyboard when clicking outside
  document.addEventListener('click', (e) => {
    if (!keyboard.contains(e.target) && e.target !== searchBar) {
      keyboard.style.display = 'none';
    }
  });

  // Key press functionality
  keys.forEach(key => {
    key.addEventListener('click', () => {
      const char = key.getAttribute('data-char');
      const action = key.getAttribute('data-action');
      if (action === 'backspace') {
        searchBar.value = searchBar.value.slice(0, -1);
      } else if (char) {
        searchBar.value += char;
      }
      searchBar.focus();
    });
  });

  // Dragging functionality
  let isDragging = false;
  let currentX;
  let currentY;
  let initialX;
  let initialY;

  dragHandle.addEventListener('mousedown', (e) => {
    isDragging = true;
    initialX = e.clientX - currentX;
    initialY = e.clientY - currentY;
    dragHandle.style.cursor = 'grabbing';
  });

  document.addEventListener('mousemove', (e) => {
    if (isDragging) {
      e.preventDefault();
      currentX = e.clientX - initialX;
      currentY = e.clientY - initialY;
      keyboard.style.left = `${currentX}px`;
      keyboard.style.top = `${currentY}px`;
      keyboard.style.transform = 'none';
    }
  });

  document.addEventListener('mouseup', () => {
    isDragging = false;
    dragHandle.style.cursor = 'move';
  });

  // Position keyboard
  function positionKeyboard() {
    const searchBarRect = searchBar.getBoundingClientRect();
    const keyboardRect = keyboard.getBoundingClientRect();

    // On desktop, position to the right
    currentX = searchBarRect.right + 10;
    currentY = searchBarRect.top;

    // Ensure it doesn't go off-screen
    const maxX = window.innerWidth - keyboardRect.width - 10;
    const maxY = window.innerHeight - keyboardRect.height - 10;
    currentX = Math.min(Math.max(currentX, 0), maxX);
    currentY = Math.min(Math.max(currentY, 0), maxY);

    keyboard.style.left = `${currentX}px`;
    keyboard.style.top = `${currentY}px`;
    keyboard.style.transform = 'none';
  }

  // Reposition on window resize (only if visible)
  window.addEventListener('resize', () => {
    if (keyboard.style.display === 'block' && !isMobile()) {
      positionKeyboard();
    } else if (isMobile()) {
      keyboard.style.display = 'none'; // Hide if resized to mobile
    }
  });
});