import { Directive } from '@angular/core';
import { DynamicIconDirective } from './dynamic-icon.directive';

@Directive({ 
  selector: '[leadingVisual]', 
  hostDirectives: [
    {
      directive: DynamicIconDirective,
      inputs: ['icon', 'size']
    },
  ]
})
export class LeadingVisualDirective {

}

@Directive({ 
  selector: '[trailingVisual]',
  hostDirectives: [
    {
      directive: DynamicIconDirective,
      inputs: ['icon', 'size']
    }
  ],
})
export class TrailingVisualDirective {}

@Directive({ selector: '[trailingAction]' })
export class TrailingActionDirective {}
