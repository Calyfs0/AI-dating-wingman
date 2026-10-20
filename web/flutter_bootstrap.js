{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      document.getElementById('loading')?.remove();
      await appRunner.runApp();
    } catch (err) {
      console.error('Flutter boot failed', err);
      const el = document.getElementById('loading');
      if (el) {
        el.style.whiteSpace = 'pre-wrap';
        el.style.letterSpacing = 'normal';
        el.style.textTransform = 'none';
        el.style.padding = '24px';
        el.textContent = 'Failed to load Kehlo:\n' + err;
      }
    }
  },
});
