import { test } from '@playwright/test';
test('checkout', async ({ page }) => { await page.goto('/checkout'); });
