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

/* eslint-disable @angular-eslint/component-selector, @angular-eslint/no-input-rename */

import { ChangeDetectionStrategy, Component, computed, contentChild, input, output } from '@angular/core';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import { IconModule } from '../icon/icon.module';
import { AbstractBaseButtonDirective } from './abstract-base-button.directive';
import { PrimerBaseButtonDirective } from './base-button.directive';
import { DynamicIconDirective } from './dynamic-icon.directive';
import { LeadingVisualDirective, TrailingActionDirective, TrailingVisualDirective } from './button-markers';

type Scheme = 'default' | 'primary' | 'secondary' | 'danger' | 'invisible';
type Size = 'small' | 'medium' | 'large';

@Component({
  selector: 'button[primerButton]',
  templateUrl: './button.component.html',
  host: {
    'type': 'button',
    'class': 'Button',
    '[class.Button--primary]': "scheme() === 'primary'",
    '[class.Button--secondary]': "scheme() === 'default' || scheme() === 'secondary'",
    '[class.Button--danger]': "scheme() === 'danger'",
    '[class.Button--invisible]': "scheme() === 'invisible'"
  },
  imports: [
    PrimerBaseButtonDirective, 
    TrailingActionDirective, 
    TrailingVisualDirective, 
    LeadingVisualDirective, 
    DynamicIconDirective, 
    IconModule
  ],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PrimerButtonComponent extends AbstractBaseButtonDirective  {
  readonly leadingVisual = contentChild(LeadingVisualDirective, { descendants: true });
  readonly trailingVisual = contentChild(TrailingVisualDirective, { descendants: true });
  readonly trailingAction = contentChild(TrailingActionDirective, { descendants: true });

  readonly buttonId = input(generateId('icon-button'));
  readonly buttonClass = input('', { alias: 'button-class' });

  readonly icon = input<string>();
  readonly scheme = input<Scheme>('default');
  readonly size = input<Size>('medium');

  readonly hasLeadingVisual = computed(() => !!this.leadingVisual());
  readonly hasTrailingVisual = computed(() => !!this.trailingVisual());
  readonly hasTrailingAction = computed(() => !!this.trailingAction());

  /**
   * String that can be read by assistive technology. A label should be short
   * and concise. See the accessibility section for more information.
   */
  readonly label = input<string>();

  /**
   * String that can be read by assistive technology. A description can be
   * longer as it is intended to provide more context and information. See the
   * accessibility section for more information.
   */
  readonly description = input<string>();

  /**
   * Whether or not to show a tooltip when this button is hovered. Tooltips
   * should only be hidden if the aria label is redundant, i.e. if the icon has
   * a widely understood definition.
   *
   * @default true
   */
  readonly showTooltip = input(true);
  readonly tooltipId = input(generateId('tooltip'));
  //readonly tooltipDirection = input<TooltipDirection>('s', { alias: 'tooltip-direction' });

  readonly clicked = output();

  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  readonly tooltipText = computed(() => this.description() || this.label());
  readonly tooltipType = computed(() => this.description() ? 'description' : 'label');

  readonly ariaLabel = computed(() => this.whenNoTooltip(() => this.label()));
  readonly ariaDescription = computed(() => this.whenNoTooltip(() => this.description()));

  readonly ariaLabelledBy = computed(() =>
    this.whenTooltipType('label', () => this.tooltipId())
  );

  readonly ariaDescribedBy = computed(() =>
    this.whenTooltipType('description', () => this.tooltipId())
  );

  private whenNoTooltip<T>(value:() => T) {
    return this.showTooltip() ? undefined : value();
  }

  private whenTooltipType<T>(type:'label' | 'description', value:() => T) {
    return this.showTooltip() && this.tooltipType() === type
      ? value()
      : undefined;
  }
}
