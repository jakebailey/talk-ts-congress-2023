<template>
  <Line :data="data" :options="options" />
</template>

<script lang="ts">
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";
import { Line } from "vue-chartjs";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default {
  name: "TSReleaseByLines",
  components: {
    Line,
  },
  props: ["theme"],
  data() {
    const data: [label: string, value: number][] = [
      ["0.8", 31691],
      ["0.9", 70493],
      ["1.0", 70470],
      ["1.1", 71599],
      ["1.3", 74157],
      ["1.4", 77156],
      ["1.5", 64389],
      ["1.6", 70617],
      ["1.7", 70827],
      ["1.8", 75482],
      ["2.0", 101437],
      ["2.1", 116300],
      ["2.2", 121649],
      ["2.3", 127394],
      ["2.4", 130602],
      ["2.5", 134393],
      ["2.6", 147204],
      ["2.7", 153366],
      ["2.8", 156955],
      ["2.9", 167072],
      ["3.0", 173682],
      ["3.1", 180730],
      ["3.2", 187227],
      ["3.3", 195005],
      ["3.4", 195438],
      ["3.5", 197774],
      ["3.6", 206488],
      ["3.7", 215547],
      ["3.8", 224261],
      ["3.9", 229617],
      ["4.0", 240172],
      ["4.1", 244368],
      ["4.2", 249624],
      ["4.3", 261415],
      ["4.4", 265228],
      ["4.5", 269168],
      ["4.6", 271921],
      ["4.7", 275858],
      ["4.8", 279077],
      ["4.9", 280780],
      ["5.0", 306081],
    ];

    return {
      data: {
        labels: data.map((x) => x[0]),
        datasets: [
          {
            label: "Lines of code",
            backgroundColor: this.theme === "dark" ? "#ff5722" : "#285577",
            borderColor: this.theme === "dark" ? "#451100" : "#91bada",
            data: data.map((x) => x[1]),
          },
        ],
      },
      options: {
        responsive: true,
        devicePixelRatio: 4,
        animation: {
          duration: 0,
        },
        scales: {
          x: {
            grid: {
              color: this.theme === "dark" ? "#222" : undefined,
            },
          },
          y: {
            beginAtZero: true,
            grid: {
              color: this.theme === "dark" ? "#222" : undefined,
            },
          },
        },
        // maintainAspectRatio: false,
      },
    };
  },
};
</script>
