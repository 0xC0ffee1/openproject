/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import type { Plugin } from 'esbuild';
import * as fs from 'fs';

const customConfigPlugin:Plugin = {
  name: 'custom-config',
  setup({ initialOptions: options }) {
    if (options.chunkNames === '[name]-[hash]') { // named chunks
      options.chunkNames = '[dir]/[name]-[hash]';
    }
  }
}

const jqueryInjectionPlugin:Plugin = {
  name: 'jquery-injection',
  setup(build) {
    const path = require('path');

    // Intercept the import of 'core-vendor/enjoyhint'
    build.onResolve({ filter: /^core-vendor\/enjoyhint$/ }, () => {
      return {
        path: 'enjoyhint-with-jquery',
        namespace: 'jquery-wrapper',
      };
    });

    // Provide the wrapper content
    build.onLoad({ filter: /.*/, namespace: 'jquery-wrapper' }, async () => {
      const workingDir = build.initialOptions.absWorkingDir || process.cwd();
      const enjoyhintPath = path.join(workingDir, 'src', 'vendor', 'enjoyhint.js');
      const contents = await fs.promises.readFile(enjoyhintPath, 'utf8');

      // Wrap with jQuery import
      const wrappedCode = `
import jQuery from 'jquery';
window.jQuery = jQuery;
window.$ = jQuery;

${contents}
`;

      return {
        contents: wrappedCode,
        loader: 'js',
        resolveDir: path.join(workingDir, 'src'),
      };
    });
  }
}

export default [customConfigPlugin, jqueryInjectionPlugin];
