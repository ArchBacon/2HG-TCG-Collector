import { Controller } from '@hotwired/stimulus';
import { GAMES } from '../games.js';

export default class extends Controller {
    connect() {
        const params = new URLSearchParams(window.location.search);
        const selected = params.get('game') || GAMES[0].code;

        for (const game of GAMES) {
            const option = document.createElement('option');
            option.value = game.code;
            option.textContent = game.label;
            option.selected = game.code === selected;
            this.element.appendChild(option);
        }
    }
}
