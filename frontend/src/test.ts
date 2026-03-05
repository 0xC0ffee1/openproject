// This file is required by karma.conf.js and loads recursively all the .spec and framework files

import { getTestBed } from '@angular/core/testing';
import { NgModule, provideZonelessChangeDetection } from '@angular/core';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from '@angular/platform-browser-dynamic/testing';
import { I18n } from 'i18n-js';
import { registerDialogStreamAction } from 'core-turbo/dialog-stream-action';

registerDialogStreamAction();

// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
(window as any).global = window;

// Declare global I18n shim
window.I18n = new I18n();

@NgModule({
  imports: [BrowserDynamicTestingModule],
  exports: [BrowserDynamicTestingModule],
  providers: [provideZonelessChangeDetection()],
})
class ZonelessBrowserDynamicTestingModule {}

// First, initialize the Angular testing environment.
getTestBed().initTestEnvironment(
  ZonelessBrowserDynamicTestingModule,
  platformBrowserDynamicTesting(),
  {
    teardown: { destroyAfterEach: false },
  },
);
