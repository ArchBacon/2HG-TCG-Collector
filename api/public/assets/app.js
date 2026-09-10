const GAMES = [
    { code: 'mtg', label: 'Magic: The Gathering' },
    { code: 'pokemon', label: 'Pokémon' },
    { code: 'lorcana', label: 'Disney Lorcana' },
    { code: 'onepiece', label: 'One Piece' },
];

function populateGameSelect(select, selected) {
    for (const game of GAMES) {
        const option = document.createElement('option');
        option.value = game.code;
        option.textContent = game.label;
        if (game.code === selected) {
            option.selected = true;
        }
        select.appendChild(option);
    }
}
