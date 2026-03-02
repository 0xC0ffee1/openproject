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

import { Controller } from '@hotwired/stimulus';
import { retrieveCkEditorInstance } from 'core-app/shared/helpers/ckeditor-helpers';

export default class extends Controller {
  static values = { autofocus: Boolean };
  declare autofocusValue:boolean;

  static targets = ['editor'];
  declare readonly editorTarget:HTMLElement;

  connect():void {
    if (this.autofocusValue) {
      const x = parseInt(document.body.dataset.inplaceEditClickX ?? '', 10);
      const y = parseInt(document.body.dataset.inplaceEditClickY ?? '', 10);
      delete document.body.dataset.inplaceEditClickX;
      delete document.body.dataset.inplaceEditClickY;

      const coords = !isNaN(x) && !isNaN(y) ? { x, y } : null;
      setTimeout(() => { this.focusInput(coords); }, 100);
    }
  }

  focusInput(coords?:{ x:number; y:number }|null):void {
    this.element.scrollIntoView({ block: 'center' });
    const editor = retrieveCkEditorInstance(this.editorTarget);
    if (!editor) return;

    if (coords) {
      try {
        // The actual editor is slightly offset, so we need to adjust the coordinates
        const domRange = document.caretRangeFromPoint?.(coords.x + 10, coords.y + 50) ?? null;
        const editableEl = this.editorTarget.querySelector('.ck-editor__editable_inline');

        if (domRange && editableEl?.contains(domRange.startContainer)) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any,@typescript-eslint/no-unsafe-assignment
          const ck = editor as any;
          const viewRange = ck.editing.view.domConverter.domRangeToView(domRange);
          if (viewRange) {
            const modelRange = ck.editing.mapper.toModelRange(viewRange);
            ck.model.change((writer:any) => { writer.setSelection(modelRange); });
            editor.editing.view.focus();
            return;
          }
        }
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
      } catch (e) {
        // Fall through to default focus
      }
    }

    editor.editing.view.focus();
  }
}
