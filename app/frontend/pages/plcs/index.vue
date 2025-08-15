<template>
  <Button @click="increment">Count is: {{ count }}</button>
  <Calendar v-model="date" />
  <Dropdown v-model="selectedCity" :options="cities" optionLabel="name" placeholder="Select a City" />
  <InputSwitch v-model="checked" />
  <v-container>
    <div v-for="plc in plcs" :key="plc.id" class="pa-4">
      <v-card :text="plc.name" />
    </div>
  </v-container>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';

  const count = ref(0);

  const date = ref(new Date());

  const selectedCity = ref();
  const cities = ref([
    { name: 'New York', code: 'NY' },
    { name: 'Rome', code: 'RM' },
    { name: 'London', code: 'LDN' },
    { name: 'Istanbul', code: 'IST' },
    { name: 'Paris', code: 'PRS' }
  ]);

  const checked = ref(false);

  function increment() {
    count.value++
  }

  onMounted(() => {
    console.log(`The initial count is ${count.value}.`)
  });

  defineProps(['plcs']);
</script>
