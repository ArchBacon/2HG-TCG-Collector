import { Controller } from '@hotwired/stimulus';
import { GAMES } from '../games.js';

export default class extends Controller {
    static targets = ['game', 'query', 'status', 'results', 'pagination', 'prevButton', 'nextButton', 'pageInfo'];

    connect() {
        const params = new URLSearchParams(window.location.search);
        const game = params.get('game') || GAMES[0].code;
        const query = params.get('q') || '';

        this.currentPage = Math.max(1, parseInt(params.get('page'), 10) || 1);
        this.totalPages = 1;
        this.queryTarget.value = query;

        if (query) {
            this.runSearch(game, query, this.currentPage);
        }
    }

    submit(event) {
        event.preventDefault();
        this.navigate(this.gameTarget.value, this.queryTarget.value.trim(), 1);
    }

    prev() {
        if (this.currentPage > 1) {
            this.navigate(this.gameTarget.value, this.queryTarget.value.trim(), this.currentPage - 1);
        }
    }

    next() {
        if (this.currentPage < this.totalPages) {
            this.navigate(this.gameTarget.value, this.queryTarget.value.trim(), this.currentPage + 1);
        }
    }

    navigate(game, q, page) {
        const url = new URL(window.location.href);
        url.searchParams.set('game', game);
        url.searchParams.set('q', q);
        url.searchParams.set('page', String(page));
        window.history.pushState({}, '', url);
        this.runSearch(game, q, page);
    }

    async runSearch(game, q, page) {
        this.resultsTarget.innerHTML = '';
        this.paginationTarget.hidden = true;

        if (!q) {
            this.statusTarget.textContent = '';
            return;
        }

        this.statusTarget.textContent = 'Searching…';

        try {
            const response = await fetch(`/api/${game}/cards.jsonld?name=${encodeURIComponent(q)}&page=${page}`, {
                headers: { Accept: 'application/ld+json' },
            });
            if (!response.ok) {
                throw new Error(`Request failed (${response.status})`);
            }

            const data = await response.json();
            const cards = data.member || [];

            if (cards.length === 0) {
                this.statusTarget.textContent = page > 1 ? 'No more results.' : `No cards found for "${q}".`;
                return;
            }

            this.currentPage = page;
            const lastPageMatch = data.view?.last?.match(/page=(\d+)/);
            this.totalPages = lastPageMatch ? parseInt(lastPageMatch[1], 10) : 1;
            this.statusTarget.textContent = `${data.totalItems} card(s) found.`;

            for (const card of cards) {
                this.resultsTarget.insertAdjacentHTML('beforeend', this.cardTemplate(card, game));
            }

            if (this.totalPages > 1) {
                this.pageInfoTarget.textContent = `Page ${this.currentPage} of ${this.totalPages}`;
                this.prevButtonTarget.disabled = this.currentPage <= 1;
                this.nextButtonTarget.disabled = this.currentPage >= this.totalPages;
                this.paginationTarget.hidden = false;
            }
        } catch (err) {
            this.statusTarget.textContent = `Error: ${err.message}`;
        }
    }

    cardTemplate(card, game) {
        const tcg = card.tcg ?? game;
        const fallback = `/${tcg}/medium/fallback.webp`;
        const image = card.images?.medium ?? card.images?.small ?? card.images?.large ?? fallback;
        const name = this.escapeHtml(card.name);
        const meta = [card.number, card.rarity].filter(Boolean).map((v) => this.escapeHtml(v)).join(' · ');

        return `
            <div class="group overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-slate-200 transition hover:shadow-md">
                <img src="${this.escapeHtml(image)}" alt="${name}" loading="lazy"
                     data-fallback="${this.escapeHtml(fallback)}" data-action="error->search#imageFallback"
                     class="aspect-[5/7] w-full bg-slate-100 object-cover">
                <div class="p-2">
                    <div class="truncate text-sm font-medium text-slate-700">${name}</div>
                    ${meta ? `<div class="truncate text-xs text-slate-400">${meta}</div>` : ''}
                </div>
            </div>
        `;
    }

    imageFallback(event) {
        const img = event.currentTarget;
        const fallback = img.dataset.fallback;

        // Only swap once, so a missing fallback can't cause an error loop.
        if (fallback && !img.src.endsWith(fallback)) {
            img.src = fallback;
        }
    }

    escapeHtml(value) {
        const div = document.createElement('div');
        div.textContent = value ?? '';
        return div.innerHTML;
    }
}
