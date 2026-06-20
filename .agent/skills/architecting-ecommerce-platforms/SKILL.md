---
name: architecting-ecommerce-platforms
description: Orchestrates the creation of large-scale, multi-page applications like e-commerce sites (e.g., Newegg) with dynamic routing, complex state management (Zustand/Context), and a component hierarchy designed for scale.
---

# Architecting E-commerce Platforms Skill

## When to use this skill
- When the user asks to build an e-commerce site, marketplace, or SaaS with multiple interconnected pages.
- When the user references sites like Newegg, Amazon, or complex web applications rather than just a landing page.
- When the `full-web-dev-pipeline` needs to branch out from a single page into dynamic routing and centralized data structures.

## Tone & Language Guidelines
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "يا معلم، بما إنو بنبني موقع زي Newegg، ما بضبط نكتب الشغل كله بصفحة وحدة، لازم نبني Data Architecture صح ونعمل Dynamic Routes عشان كل منتج يفتح بصفحة لحاله."

## 1. The Core Philosophy (Beyond the Landing Page)
Unlike simple landing pages where you just apply UI skills, an e-commerce platform requires **Architecture First**.

If the user requests an e-commerce site, you must enforce this structure before writing any visuals:
1. **Products Database/Mock Data:** A centralized place for all data.
2. **State Management:** A cart system that persists across pages.
3. **Dynamic Routing:** A way to handle `/product/[id]`.
4. **Reusable Components:** Cards, Headers, Footers that live outside any specific page.

## 2. Setting Up the Ecosystem (Next.js App Router)

### A. The Data Layer (`lib/products.ts`)
Never hardcode products into UI components.
Create a mock database (or connect to a real DB if specified) that exports the data typing and the array.

```typescript
// lib/products.ts
export type Product = {
  id: string;
  name: string;
  price: number;
  slug: string; // Crucial for URLs like /product/alienware-15
  image: string;
  specs: {
    cpu: string;
    ram: string;
    storage: string;
  };
};

export const products: Product[] = [
  /* Extracted from images or reliable-content-scraper */
];
```

### B. Global State (The Cart)
For an e-commerce flow, the Cart must be globally accessible so the Navbar can show the count, and the Checkout page can see the items. Use `React Context` or `Zustand`.

```tsx
// components/CartProvider.tsx (Simple Context Example)
"use client";
import React, { createContext, useContext, useState } from 'react';

type CartItem = { product: Product; quantity: number };

const CartContext = createContext<any>(null);

export const CartProvider = ({ children }: { children: React.ReactNode }) => {
  const [cart, setCart] = useState<CartItem[]>([]);
  // functions: addToCart, removeFromCart, updateQuantity
  return <CartContext.Provider value={{ cart }}>{children}</CartContext.Provider>;
};
```
*Instruct the user to wrap their `layout.tsx` in `<CartProvider>`.*

### C. Dynamic Routing (The Product Page)
Explain to the user how Next.js App Router handles dynamic segments.

Create `app/product/[slug]/page.tsx`:
```tsx
import { products } from '@/lib/products';
import { notFound } from 'next/navigation';

export default function ProductPage({ params }: { params: { slug: string } }) {
  const product = products.find(p => p.slug === params.slug);
  
  if (!product) return notFound();

  return (
    <div className="container mx-auto">
      <h1>{product.name}</h1>
      <p>{product.price} JOD</p>
      {/* UI Skills go here: high-end-tech-ui for the Add to Cart button */}
    </div>
  );
}
```

## 3. Workflow Checklist
If tasked to build an e-commerce site:
1. **Establish the Schema:** Ask the user what fields a product needs (Price, Specs, Variants).
2. **Setup Routing Structure:** Create `app/(shop)/page.tsx` (Home), `app/cart/page.tsx` (Cart), and `app/product/[slug]/page.tsx` (Item Details).
3. **Setup Context/Store:** Implement the cart state.
4. **Build the `ProductCard`:** Create one highly reusable `ProductCard.tsx` that links to the dynamic route using `<Link href={"/product/" + product.slug}>`.
5. **Apply UI Skills:** Once the skeleton is connected, invoke `high-end-tech-ui` or `advanced-scroll-animations` to make the product pages and cards look premium.
6. Tell the user in dialect: "السيستم صار جاهز يا غالي! بنينا الهيكل تبع الـ E-commerce، السلة (Cart) صارت شغالة، وكل منتج إله رابط (URL) لحاله زي المواقع الكبيرة."
