
function main() {
  var pragmaDots = document.getElementsByClassName("pragmadots");
  for (var i = 0; i < pragmaDots.length; i++) {
    pragmaDots[i].onclick = function(event) {
      // Hide tease
      event.target.parentNode.style.display = "none";
      // Show actual
      event.target.parentNode.nextElementSibling.style.display = "inline";
    }
  }

  const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
  function switchTheme(e) {
      if (e.target.checked) {
          document.documentElement.setAttribute('data-theme', 'dark');
          localStorage.setItem('theme', 'dark');
      } else {
          document.documentElement.setAttribute('data-theme', 'light');
          localStorage.setItem('theme', 'light');
      }
  }

  toggleSwitch.addEventListener('change', switchTheme, false);

  const currentTheme = localStorage.getItem('theme') ? localStorage.getItem('theme') : null;
  if (currentTheme) {
    document.documentElement.setAttribute('data-theme', currentTheme);

    if (currentTheme === 'dark') {
      toggleSwitch.checked = true;
    }
  }
}