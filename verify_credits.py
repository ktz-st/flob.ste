"""Verify credits pixels, palettes and seven-slide presentation in Hatari."""
from verify_score import main

if __name__ == '__main__':
    main('VERIFY_CREDITS', 'CREDITS.TXT', 'credits', 'PASS seven credits slides', 'DONE')
