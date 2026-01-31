import { Controller } from '@hotwired/stimulus';

import 'core-app/core/setup-legacy/init-jquery';
import 'core-vendor/jquery.jeditable.mini';
import 'core-vendor/jquery.colorcontrast';

import './common';
import './model';
import './editable_inplace';
import './sprint';
import './work_package';
import './task';
import './impediment';
import './taskboard';
import './show_main';

export default class TaskboardLegacyController extends Controller {
}
