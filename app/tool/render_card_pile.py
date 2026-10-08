"""Renders the "pile of cards" backgrounds to images, one per game plus one mixing all games.

Building this pile at runtime out of ~150 separately rotated and shadowed card widgets cost ~17ms
per frame while scrolling; a single pre-rendered image ~7ms. The app applies the blur, saturation
and color cover on top (GameBackdrop in lib/ui/shared/glass/game_backdrop.dart, with the values
in GlassTheme), so those stay tweakable.

Usage (from the app folder):  python tool/render_card_pile.py
Output: assets/backgrounds/<slug>.jpg and assets/backgrounds/all.jpg
Needs Pillow with WebP support (pip install pillow).
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

APP = Path(__file__).resolve().parent.parent
CARDBACKS = APP / 'assets' / 'tcgs'
OUT = APP / 'assets' / 'backgrounds'

GAMES = ['pokemon', 'mtg', 'onepiece', 'lorcana', 'dragonballfusion']

# Output size: portrait phone proportions. The app blurs it and scales it to cover the screen, so
# it doesn't need to be large; at this size the cards are drawn at about their source resolution.
WIDTH, HEIGHT = 720, 1560
SUPERSAMPLE = 2  # Drawn at 2x and scaled down, for smooth rotated edges
BACKGROUND = (21, 23, 28)  # Shows in the (rare) gaps between cards; the app's color cover goes over it

# Layout of the pile
CARD_WIDTH = 0.2  # Of the image width: about 5 cards across
CARD_ASPECT = 146 / 204  # Width / height of the cardback images
STEP_X, STEP_Y = 0.68, 0.52  # Grid step, as a fraction of the card size: heavy overlap
MAX_ANGLE = 40  # Degrees, either way
CORNER = 0.07  # Corner radius, as a fraction of the card width
SHADOW_BLUR = 0.08  # Fractions of the card width
SHADOW_OFFSET = (0.014, 0.04)
SHADOW_ALPHA = 0.4


def card_image(path, width, height):
    """The cardback at the given size, with rounded corners (transparent outside them)."""
    card = Image.open(path).convert('RGBA').resize((width, height), Image.LANCZOS)
    mask = Image.new('L', (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius=int(width * CORNER), fill=255)
    card.putalpha(mask)
    return card


def shadow_for(card, card_width):
    """A soft black shadow in the shape of the (rotated) card, with room around it for the blur."""
    blur = max(1, int(card_width * SHADOW_BLUR))
    pad = blur * 3
    alpha = Image.new('L', (card.width + pad * 2, card.height + pad * 2), 0)
    alpha.paste(card.getchannel('A').point(lambda a: int(a * SHADOW_ALPHA)), (pad, pad))
    shadow = Image.new('RGBA', alpha.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(blur)))
    return shadow


def composite(canvas, image, cx, cy):
    """Draws image centered on (cx, cy), cropping whatever falls outside the canvas."""
    left, top = int(round(cx - image.width / 2)), int(round(cy - image.height / 2))
    dst_left, dst_top = max(0, left), max(0, top)
    right = min(canvas.width, left + image.width)
    bottom = min(canvas.height, top + image.height)
    if right <= dst_left or bottom <= dst_top:
        return
    src_left, src_top = dst_left - left, dst_top - top
    box = (src_left, src_top, src_left + right - dst_left, src_top + bottom - dst_top)
    canvas.alpha_composite(image, (dst_left, dst_top), box)


def render(slugs, seed):
    rng = random.Random(seed)
    w, h = WIDTH * SUPERSAMPLE, HEIGHT * SUPERSAMPLE
    card_w = int(w * CARD_WIDTH)
    card_h = int(card_w / CARD_ASPECT)
    cards = {slug: card_image(CARDBACKS / f'{slug}.webp', card_w, card_h) for slug in slugs}

    # Positions on a jittered grid, a bit larger than the image so no edge is left bare
    placements = []
    y = -card_h * 0.5
    while y < h + card_h * 0.2:
        x = -card_w * 0.5
        while x < w + card_w * 0.2:
            placements.append((
                rng.choice(slugs),
                x + (rng.random() - 0.5) * card_w * 0.6,
                y + (rng.random() - 0.5) * card_h * 0.5,
                (rng.random() - 0.5) * 2 * MAX_ANGLE,
            ))
            x += card_w * STEP_X
        y += card_h * STEP_Y
    rng.shuffle(placements)  # Random stacking order, so rows don't visibly overlap the same way

    canvas = Image.new('RGBA', (w, h), BACKGROUND + (255,))
    for slug, left, top, angle in placements:
        card = cards[slug].rotate(angle, resample=Image.BICUBIC, expand=True)
        cx, cy = left + card_w / 2, top + card_h / 2  # Rotated around its center
        composite(canvas, shadow_for(card, card_w), cx + card_w * SHADOW_OFFSET[0], cy + card_w * SHADOW_OFFSET[1])
        composite(canvas, card, cx, cy)

    return canvas.convert('RGB').resize((WIDTH, HEIGHT), Image.LANCZOS), len(placements)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = [(slug, [slug]) for slug in GAMES] + [('all', GAMES)]
    for i, (name, slugs) in enumerate(jobs):
        image, count = render(slugs, seed=1000 + i)
        path = OUT / f'{name}.jpg'
        image.save(path, quality=85, optimize=True, progressive=True)
        print(f'{path.relative_to(APP)}: {count} cards, {path.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
