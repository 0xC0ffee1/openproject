'use strict';

const { createBuilder } = require('@angular-devkit/architect');
const { execute } = require('@angular-devkit/build-angular/src/builders/karma');

const PRIMER_DIST_CSS = /[\\/]node_modules[\\/]@primer[\\/]react[\\/]dist[\\/].+\.css$/;

async function* karmaWithPrimerCss(options, context) {
  yield* execute(options, context, {
    webpackConfiguration: async (webpackConfig) => {
      webpackConfig.module ??= {};
      webpackConfig.module.rules ??= [];

      webpackConfig.module.rules.unshift({
        test: /\.css$/i,
        include: PRIMER_DIST_CSS,
        type: 'asset/source',
      });

      return webpackConfig;
    },
  });
}

module.exports = createBuilder(karmaWithPrimerCss);
