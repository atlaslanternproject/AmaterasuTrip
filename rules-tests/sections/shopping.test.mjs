// Test delle regole Firestore di Shopping (trips/{tripId}/shoppingItems) e
// della valigia (packingItems): controlli comuni delle sezioni più nome,
// per chi, dove, comprato, prezzo reale, persona, quantità e spuntata.

import {test} from 'node:test';

import {
  MEMBER,
  assertSucceeds,
  base,
  sectionCommonTests,
  setDoc,
  setupSectionRules,
} from './section-rules-support.mjs';

setupSectionRules('demo-amaterasu-shopping-rules');

function shopping(uid, extra = {}) {
  return {...base(uid), name: 'Tè matcha', bought: false, ...extra};
}

function packing(uid, extra = {}) {
  return {...base(uid), name: 'Adattatore', packed: false, ...extra};
}

const shop = sectionCommonTests('shoppingItems', 'shoppingItems', shopping, [
  {name: ''},
  {bought: 'no'},
  {forUid: 5},
  {where: 'x'.repeat(201)},
  {actualCostMinorUnits: 100},
  {actualCostMinorUnits: 0, actualCostCurrency: 'JPY'},
  {actualCostMinorUnits: 100, actualCostCurrency: 'yen'},
  {forText: 'x'.repeat(121)},
  {priority: 'C'},
  {boughtByUid: 7},
], {bought: true, actualCostMinorUnits: 1200, actualCostCurrency: 'JPY'});

const pack = sectionCommonTests('packingItems', 'packingItems', packing, [
  {name: ''},
  {packed: 1},
  {quantity: 0},
  {quantity: 100},
  {quantity: 1.5},
  {personUid: ['bob']},
], {packed: true});

test('shopping and packing: every optional field', async () => {
  await assertSucceeds(setDoc(shop.ref(MEMBER, 'full'), shopping(MEMBER, {
    forUid: MEMBER,
    where: 'Nishiki Market',
    bought: true,
    estimatedCostMinorUnits: 1500,
    estimatedCostCurrency: 'JPY',
    actualCostMinorUnits: 1200,
    actualCostCurrency: 'JPY',
    notes: 'Per la nonna',
    expenseId: 'e1',
    forText: 'Nonna',
    priority: 'SS',
    boughtByUid: MEMBER,
  })));
  await assertSucceeds(setDoc(pack.ref(MEMBER, 'full'), packing(MEMBER, {
    personUid: MEMBER, quantity: 2, packed: true,
  })));
});
