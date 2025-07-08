// @ts-check
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Agent-NN Documentation',
  url: 'https://EcoSphereNetwork.github.io',
  baseUrl: '/Agent-NN/',
  organizationName: 'EcoSphereNetwork',
  projectName: 'Agent-NN',
  trailingSlash: false,
  favicon: 'img/favicon.ico',
  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */ ({
        docs: {
          path: 'docs',
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],
};
module.exports = config;
