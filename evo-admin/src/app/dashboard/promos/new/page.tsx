'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function PromosNewPage() {
  const router = useRouter();
  useEffect(() => {
    router.replace('/dashboard/promos');
  }, [router]);

  return (
    <div className="flex items-center justify-center h-40">
      <div className="w-8 h-8 border-2 border-[#00C853] border-t-transparent rounded-full animate-spin" />
    </div>
  );
}
