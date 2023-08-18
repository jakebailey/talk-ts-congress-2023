<template>
  <footer
    v-if="$slidev.nav.currentLayout !== 'cover' && $slidev.nav.currentPage !== $slidev.nav.total"
    class="absolute bottom-0 right-1 p-2"
  >
    <p style="font-size: small;">{{ $slidev.nav.currentPage }}</p>
  </footer>
</template>
