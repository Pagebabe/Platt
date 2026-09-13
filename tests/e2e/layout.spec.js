const { test, expect } = require('@playwright/test');

async function acceptAgeGate(page){
  const gate=page.locator('#ageYes');
  if(await gate.count()) await gate.click();
}

async function expectNoHorizontalOverflow(page){
  const sizes=await page.evaluate(()=>({
    viewport:document.documentElement.clientWidth,
    scroll:document.documentElement.scrollWidth
  }));
  expect(sizes.scroll).toBeLessThanOrEqual(sizes.viewport+1);
}

test('public discovery layout stays usable without horizontal overflow',async({page})=>{
  await page.goto('/index.html');
  await acceptAgeGate(page);
  await expect(page.getByRole('heading',{name:/Entdecke passende Profile/i})).toBeVisible();
  await expect(page.getByRole('button',{name:'Profile finden'})).toBeVisible();
  await expect(page.locator('.value-strip')).toBeVisible();
  await expect(page.locator('#listingGrid .card').first()).toBeVisible();
  await expectNoHorizontalOverflow(page);
});

test('mobile discovery keeps primary actions and cards inside viewport',async({page,isMobile})=>{
  test.skip(!isMobile,'mobile project only');
  await page.goto('/index.html');
  await acceptAgeGate(page);
  await expect(page.getByRole('button',{name:'Profile finden'})).toBeVisible();
  const buttonBox=await page.getByRole('button',{name:'Profile finden'}).boundingBox();
  const viewport=page.viewportSize();
  expect(buttonBox).not.toBeNull();
  expect(buttonBox.x).toBeGreaterThanOrEqual(0);
  expect(buttonBox.x+buttonBox.width).toBeLessThanOrEqual(viewport.width+1);
  const firstCard=page.locator('#listingGrid .card').first();
  await expect(firstCard).toBeVisible();
  const cardBox=await firstCard.boundingBox();
  expect(cardBox).not.toBeNull();
  expect(cardBox.x).toBeGreaterThanOrEqual(0);
  expect(cardBox.x+cardBox.width).toBeLessThanOrEqual(viewport.width+1);
  await expectNoHorizontalOverflow(page);
});

test('provider landing preserves clear primary action and pricing hierarchy',async({page})=>{
  await page.goto('/anbieter.html');
  await expect(page.getByRole('heading',{name:/Mehr passende Anfragen/i})).toBeVisible();
  await expect(page.getByRole('link',{name:'Kostenlos starten'}).first()).toBeVisible();
  await expect(page.getByRole('heading',{name:'Einfach und transparent'})).toBeVisible();
  await expectNoHorizontalOverflow(page);
});

test('profile mobile CTA remains reachable after navigation',async({page,isMobile})=>{
  test.skip(!isMobile,'mobile project only');
  await page.goto('/index.html');
  await acceptAgeGate(page);
  await page.locator('#listingGrid .card').first().click();
  await expect(page.locator('#profileRoot h1')).toBeVisible();
  const cta=page.locator('#mobileProfileCta');
  await expect(cta).toBeVisible();
  await expect(cta.getByRole('button',{name:/Anfrage senden/i})).toBeVisible();
  await expectNoHorizontalOverflow(page);
});
