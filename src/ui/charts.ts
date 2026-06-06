import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import type { SessionAnalytics } from '@/lib/events';

Chart.register(
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Title,
  Tooltip,
  Legend,
);

export interface ChartInstances {
  balanceChart: Chart;
  advantageChart: Chart;
}

export function createAnalyticsCharts(
  balanceCanvas: HTMLCanvasElement,
  advantageCanvas: HTMLCanvasElement,
  analytics: SessionAnalytics[],
): ChartInstances {
  const labels = analytics.map((a) => String(a.handIndex));

  const balanceChart = new Chart(balanceCanvas, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Balance',
          data: analytics.map((a) => a.balance),
          borderColor: '#4caf50',
          tension: 0.2,
        },
      ],
    },
    options: {
      responsive: true,
      plugins: { title: { display: true, text: 'Balance Over Time' } },
    },
  });

  const advantageChart = new Chart(advantageCanvas, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Advantage %',
          data: analytics.map((a) => a.estimatedAdvantage),
          borderColor: '#2196f3',
          tension: 0.2,
        },
      ],
    },
    options: {
      responsive: true,
      plugins: { title: { display: true, text: 'Estimated Advantage' } },
    },
  });

  return { balanceChart, advantageChart };
}

export function appendAnalyticsPoint(
  charts: ChartInstances,
  point: SessionAnalytics,
): void {
  charts.balanceChart.data.labels?.push(String(point.handIndex));
  charts.balanceChart.data.datasets[0].data.push(point.balance);
  charts.balanceChart.update();

  charts.advantageChart.data.labels?.push(String(point.handIndex));
  charts.advantageChart.data.datasets[0].data.push(point.estimatedAdvantage);
  charts.advantageChart.update();
}
