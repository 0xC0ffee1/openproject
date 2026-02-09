//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import jQuery from 'jquery';
import 'core-app/core/setup-legacy/init-jquery';

// Jquery UI
// import 'jquery-ui/ui/position';
// import 'jquery-ui/ui/disable-selection';
// import 'jquery-ui/ui/widgets/sortable';
// import 'jquery-ui/ui/widgets/dialog';
// import 'jquery-ui/ui/widgets/tooltip';
import 'core-vendor/jquery-ui-1.14.2/jquery-ui';

// Initialize the RB namespace on window if it doesn't exist
window.RB ??= {};

// Create a global RB reference for use in this file
const RB = window.RB;

RB.UserPreferences = {
  get(key:string) {
    return localStorage.getItem(key);
  },

  set(key:string, value:any) {
    localStorage.setItem(key, String(value));
  },
};

(function ($) {
  let object:any;
  let Factory;
  let Dialog;

  object = {
    // Douglas Crockford's technique for object extension
    // http://javascript.crockford.com/prototypal.html
    create() {
      let obj;
      let i;
      let methods;
      let methodName;

      function F() {
      }

      F.prototype = arguments[0];
      // @ts-expect-error TS(7009): 'new' expression, whose target lacks a construct s... Remove this comment to see the full error message
      obj = new F();

      // Add all the other arguments as mixins that
      // 'write over' any existing methods
      for (i = 1; i < arguments.length; i += 1) {
        methods = arguments[i];
        if (typeof methods === 'object') {
          for (methodName in methods) {
            if (methods.hasOwnProperty(methodName)) {
              obj[methodName] = methods[methodName];
            }
          }
        }
      }
      return obj;
    },
  };

  // Object factory for chiliproject_backlogs
  Factory = object.create({

    initialize(objType:any, el:any) {
      let obj;

      obj = object.create(objType);
      obj.initialize(el);
      return obj;
    },

  });

  // Utilities
  Dialog = object.create({
    msg(msg:any) {
      let dialog;
      let baseClasses;

      baseClasses = 'ui-button ui-widget ui-state-default ui-corner-all';

      if ($('#msgBox').length === 0) {
        dialog = $('<div id="msgBox"></div>').appendTo('body');
      } else {
        dialog = $('#msgBox');
      }

      dialog.html(msg);
      dialog.dialog({
        title: 'Backlogs Plugin',
        buttons: [
        {
          text: 'OK',
          class: 'button -primary',
          click() {
            $(this).dialog('close');
          },
        }],
        modal: true,
      });
      $('.button').removeClass(baseClasses);
      $('.ui-icon-closethick').prop('title', 'close');
    },
  });

  RB.Object = object;
  RB.Factory = Factory;
  RB.Dialog = Dialog;
}(jQuery));
