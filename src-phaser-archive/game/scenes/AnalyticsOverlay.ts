import { createAnalyticsCharts, appendAnalyticsPoint, type ChartInstances } from '@/ui/charts';
import type { SessionAnalytics } from '@/lib/events';

export class AnalyticsOverlay {
  private container: HTMLDivElement;
  private charts: ChartInstances | null = null;
  private visible = false;

  constructor(parent: HTMLElement) {
    this.container = document.createElement('div');
    this.container.id = 'analytics-overlay';
    this.container.style.cssText =
      'position:fixed;top:10px;right:10px;width:320px;background:rgba(0,0,0,0.85);padding:12px;border-radius:8px;display:none;z-index:1000;';
    parent.appendChild(this.container);
  }

  show(analytics: SessionAnalytics[]): void {
    if (!this.charts) {
      const balanceCanvas = document.createElement('canvas');
      const advantageCanvas = document.createElement('canvas');
      this.container.appendChild(balanceCanvas);
      this.container.appendChild(advantageCanvas);
      this.charts = createAnalyticsCharts(balanceCanvas, advantageCanvas, analytics);
    }
    this.container.style.display = 'block';
    this.visible = true;
  }

  hide(): void {
    this.container.style.display = 'none';
    this.visible = false;
  }

  toggle(analytics: SessionAnalytics[]): void {
    if (this.visible) this.hide();
    else this.show(analytics);
  }

  append(point: SessionAnalytics): void {
    if (this.charts) {
      appendAnalyticsPoint(this.charts, point);
    }
  }

  destroy(): void {
    this.charts?.balanceChart.destroy();
    this.charts?.advantageChart.destroy();
    this.container.remove();
  }
}
