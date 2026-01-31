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
import './common';

// Initialize everything after DOM is loaded
jQuery(($) => {
  let defaultDialogColor:any; // this var is used as cache for some computation in
                          // the inner function. -> Do not move to where it
                          // actually belongs!

  RB.Factory.initialize(RB.Taskboard, $('#taskboard'));

  $('#assigned_to_id_options').change(function () {
    const selected = $(this).children(':selected');
    if (!defaultDialogColor) {
      // fetch the color from the task rendered as a prototype/template for new tasks
      defaultDialogColor = $('#work_package_').css('background-color');
    }
    $(this).parents('.ui-dialog').css('background-color', selected.attr('color') || defaultDialogColor);
    // @ts-expect-error TS(2339): Property 'colorcontrast' does not exist on type 'J... Remove this comment to see the full error message
    $(this).parents('.ui-dialog').colorcontrast();
  });
});
