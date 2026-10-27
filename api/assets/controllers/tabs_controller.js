import { Controller } from '@hotwired/stimulus';

/*
 * Plain tab switcher: buttons with data-tabs-target="tab" + data-key, panels with
 * data-tabs-target="panel" + the same data-key. The server renders every panel up front.
 */
export default class extends Controller {
    static targets = ['tab', 'panel'];

    select(event) {
        const key = event.currentTarget.dataset.key;
        this.tabTargets.forEach((tab) => tab.setAttribute('aria-selected', String(tab.dataset.key === key)));
        this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.key !== key; });
    }
}
