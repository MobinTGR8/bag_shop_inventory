'use client';

import { useState } from 'react';
import { PlanBadge } from './admin/PlanBadge';
import { PLANS, type PlanConfig } from '@/types';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';

interface SimulatedPaymentProps {
  companyId: string;
  currentPlan: string;
  onComplete: () => void;
  onClose: () => void;
}

type PaymentMethod = 'bkash' | 'nagad' | 'rocket' | 'card' | null;

const PAYMENT_METHODS: {
  key: PaymentMethod;
  label: string;
  icon: string;
  gradient: string;
}[] = [
  {
    key: 'bkash',
    label: 'bKash',
    icon: '💳',
    gradient: 'from-pink-500 to-rose-600',
  },
  {
    key: 'nagad',
    label: 'Nagad',
    icon: '📱',
    gradient: 'from-orange-500 to-red-500',
  },
  {
    key: 'rocket',
    label: 'Rocket',
    icon: '🚀',
    gradient: 'from-red-500 to-red-600',
  },
  {
    key: 'card',
    label: 'Credit/Debit Card',
    icon: '💳',
    gradient: 'from-blue-500 to-blue-600',
  },
];

type Step = 'select-plan' | 'select-method' | 'enter-pin' | 'processing' | 'success';

// Confetti particles
function Confetti() {
  const colors = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4'];
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {Array.from({ length: 40 }).map((_, i) => (
        <div
          key={i}
          className="absolute rounded-full animate-float"
          style={{
            width: `${4 + Math.random() * 6}px`,
            height: `${4 + Math.random() * 6}px`,
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            backgroundColor: colors[i % colors.length],
            animationDelay: `${Math.random() * 3}s`,
            animationDuration: `${2 + Math.random() * 3}s`,
            opacity: 0.6 + Math.random() * 0.4,
          }}
        />
      ))}
    </div>
  );
}

export function SimulatedPayment({
  companyId,
  currentPlan,
  onComplete,
  onClose,
}: SimulatedPaymentProps) {
  const [step, setStep] = useState<Step>('select-plan');
  const [selectedPlan, setSelectedPlan] = useState<PlanConfig | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>(null);
  const [phoneNumber, setPhoneNumber] = useState('01');
  const [pin, setPin] = useState('');
  const [transactionId, setTransactionId] = useState('');
  const router = useRouter();

  const availablePlans = PLANS.filter(
    (p) => p.key !== currentPlan && p.key !== 'free',
  );

  function handlePlanSelect(plan: PlanConfig) {
    setSelectedPlan(plan);
    setStep('select-method');
  }

  function handleMethodSelect(method: PaymentMethod) {
    setPaymentMethod(method);
    setStep('enter-pin');
  }

  async function handlePay() {
    if (!selectedPlan) return;
    setStep('processing');

    // Simulate payment processing
    await new Promise((resolve) => setTimeout(resolve, 2500));

    const fakeTxnId = `${paymentMethod?.toUpperCase()}-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;
    setTransactionId(fakeTxnId);

    try {
      const res = await fetch(`/api/admin/tenants/${companyId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          plan: selectedPlan.key,
          max_staff: selectedPlan.max_staff,
          max_products: selectedPlan.max_products,
          max_warehouses: selectedPlan.max_warehouses,
          subscription_status: 'active',
        }),
      });
      const json = await res.json();
      if (json.company) {
        setStep('success');
        toast.success(`🎉 Plan upgraded to ${selectedPlan.label}!`);
      } else {
        toast.error('Payment failed. Please try again.');
        onClose();
      }
    } catch {
      toast.error('Network error. Please try again.');
      onClose();
    }
  }

  // Progress steps
  const steps = [
    { label: 'Plan', step: 'select-plan' as Step },
    { label: 'Payment', step: 'select-method' as Step },
    { label: 'Confirm', step: 'enter-pin' as Step },
    { label: 'Done', step: 'success' as Step },
  ];
  const currentStepIndex = steps.findIndex((s) => s.step === step);
  const progressPercent = step === 'processing'
    ? 75
    : ((currentStepIndex + 1) / steps.length) * 100;

  function ProgressHeader() {
    return (
      <div className="mb-6">
        {/* Progress bar */}
        <div className="h-1 w-full overflow-hidden rounded-full bg-surface-100 mb-4">
          <div
            className="h-full rounded-full bg-gradient-to-r from-primary-500 to-primary-600 transition-all duration-700 ease-out"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
        <div className="flex items-center justify-between">
          {steps.map((s, i) => (
            <div key={s.label} className="flex items-center gap-1.5">
              <div
                className={`flex h-7 w-7 items-center justify-center rounded-full text-[11px] font-bold transition-all duration-300 ${
                  i <= currentStepIndex
                    ? 'bg-primary-500 text-white shadow-sm shadow-primary-500/30'
                    : 'bg-surface-100 text-surface-400'
                }`}
              >
                {i < currentStepIndex || s.step === 'success' && step === 'success' ? (
                  <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  i + 1
                )}
              </div>
              <span
                className={`text-[10px] hidden sm:inline ${
                  i <= currentStepIndex
                    ? 'text-primary-600 font-medium'
                    : 'text-surface-400'
                }`}
              >
                {s.label}
              </span>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (step === 'select-plan') {
    return (
      <div className="space-y-5">
        <ProgressHeader />
        <div>
          <h3 className="text-lg font-bold text-surface-900">
            Choose a Plan
          </h3>
          <p className="text-sm text-surface-400 mt-1">
            Select the plan you want to upgrade to
          </p>
        </div>
        <div className="grid gap-3">
          {availablePlans.map((plan) => (
            <button
              key={plan.key}
              onClick={() => handlePlanSelect(plan)}
              className="flex items-center justify-between rounded-2xl border-2 border-surface-200 bg-white p-4 text-left transition-all duration-200 hover:border-primary-300 hover:shadow-lg hover:-translate-y-0.5 group"
            >
              <div className="flex items-center gap-4 min-w-0">
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary-100 to-primary-50 text-xl">
                  {plan.key === 'basic'
                    ? '🥈'
                    : plan.key === 'pro'
                      ? '🥇'
                      : '🏆'}
                </div>
                <div className="min-w-0">
                  <PlanBadge plan={plan.key} />
                  <p className="mt-0.5 text-xs text-surface-400">
                    {plan.description}
                  </p>
                </div>
              </div>
              <div className="text-right shrink-0 ml-4">
                <div className="text-lg font-bold text-surface-900">
                  {plan.price}
                </div>
                <div className="text-xs text-primary-600 font-medium opacity-0 group-hover:opacity-100 transition-opacity">
                  Select →
                </div>
              </div>
            </button>
          ))}
        </div>
        <button
          onClick={onClose}
          className="w-full text-sm text-surface-400 hover:text-surface-600 py-2 transition-colors"
        >
          Cancel
        </button>
      </div>
    );
  }

  if (step === 'select-method') {
    return (
      <div className="space-y-5">
        <ProgressHeader />

        <div className="rounded-xl bg-gradient-to-r from-primary-50 to-purple-50 border border-primary-100 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-surface-400">Amount to pay</p>
              <p className="text-2xl font-bold text-surface-900">
                {selectedPlan?.price}
              </p>
            </div>
            <PlanBadge plan={selectedPlan!.key} />
          </div>
        </div>

        <h3 className="font-semibold text-surface-900">Pay via</h3>

        <div className="grid gap-3">
          {PAYMENT_METHODS.map((m) => (
            <button
              key={m.key}
              onClick={() => handleMethodSelect(m.key)}
              className="flex items-center gap-4 rounded-2xl border-2 border-surface-200 bg-white p-4 transition-all duration-200 hover:border-primary-300 hover:shadow-lg hover:-translate-y-0.5"
            >
              <div
                className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ${m.gradient} text-white text-lg shadow-sm`}
              >
                {m.icon}
              </div>
              <div className="text-left flex-1 min-w-0">
                <div className="font-semibold text-surface-900">{m.label}</div>
                <div className="text-xs text-surface-400">
                  Fast & secure payment
                </div>
              </div>
              <svg
                className="h-5 w-5 shrink-0 text-surface-300"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          ))}
        </div>

        <button
          onClick={() => setStep('select-plan')}
          className="w-full text-sm text-surface-400 hover:text-surface-600 py-1 transition-colors"
        >
          ← Back to plans
        </button>
      </div>
    );
  }

  if (step === 'enter-pin') {
    const method = PAYMENT_METHODS.find((m) => m.key === paymentMethod)!;
    return (
      <div className="space-y-5">
        <ProgressHeader />

        <div
          className={`rounded-2xl bg-gradient-to-br ${method.gradient} p-5 text-white shadow-lg`}
        >
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white/20 text-2xl">
              {method.icon}
            </div>
            <div>
              <div className="font-semibold">{method.label} Checkout</div>
              <div className="text-sm text-white/70">
                Merchant: Bag Shop Inventory
              </div>
            </div>
          </div>
          <div className="mt-4 border-t border-white/20 pt-3">
            <div className="flex justify-between text-sm">
              <span className="text-white/70">Amount</span>
              <span className="font-bold">{selectedPlan?.price}</span>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-surface-700 mb-1.5">
              {method.label} Account Number
            </label>
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="01XXXXXXXXX"
              className="input-premium"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-surface-700 mb-1.5">
              {method.label} PIN
            </label>
            <input
              type="password"
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              placeholder="••••"
              maxLength={4}
              className="input-premium text-center text-lg tracking-[0.5em]"
              autoFocus
            />
            <p className="mt-1 text-xs text-surface-400">
              Enter any 4 digits to simulate payment
            </p>
          </div>
        </div>

        <button
          onClick={handlePay}
          disabled={pin.length < 4}
          className={`w-full rounded-xl bg-gradient-to-r ${method.gradient} px-4 py-3 font-semibold text-white shadow-lg transition-all duration-200 hover:shadow-xl hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0 disabled:cursor-not-allowed`}
        >
          Pay {selectedPlan?.price}
        </button>

        <button
          onClick={() => setStep('select-method')}
          className="w-full text-sm text-surface-400 hover:text-surface-600 py-1 transition-colors"
        >
          ← Change payment method
        </button>
      </div>
    );
  }

  if (step === 'processing') {
    const method = PAYMENT_METHODS.find((m) => m.key === paymentMethod)!;
    return (
      <div className="flex flex-col items-center justify-center py-12 space-y-6">
        <ProgressHeader />
        <div className="relative">
          <div className="h-24 w-24 animate-spin rounded-full border-[3px] border-primary-100 border-t-primary-600 shadow-lg" />
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-3xl animate-pulse">{method.icon}</div>
          </div>
        </div>
        <div className="text-center">
          <h3 className="text-lg font-bold text-surface-900">
            Processing Payment
          </h3>
          <p className="mt-1 text-sm text-surface-400 max-w-xs">
            Please wait while we process your payment via{' '}
            <strong>{method.label}</strong>
          </p>
        </div>
        <div className="flex gap-1.5">
          <span
            className="h-2.5 w-2.5 animate-bounce rounded-full bg-primary-500"
            style={{ animationDelay: '0ms' }}
          />
          <span
            className="h-2.5 w-2.5 animate-bounce rounded-full bg-primary-500"
            style={{ animationDelay: '150ms' }}
          />
          <span
            className="h-2.5 w-2.5 animate-bounce rounded-full bg-primary-500"
            style={{ animationDelay: '300ms' }}
          />
        </div>
        <p className="text-xs text-surface-400 animate-pulse">
          Do not close this page
        </p>
      </div>
    );
  }

  if (step === 'success') {
    const method = PAYMENT_METHODS.find((m) => m.key === paymentMethod)!;
    return (
      <div className="relative flex flex-col items-center justify-center py-8 space-y-6 overflow-hidden">
        <Confetti />
        <ProgressHeader />
        <div className="relative">
          <div className="flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-emerald-400 to-emerald-600 shadow-xl shadow-emerald-500/30 animate-scale-in">
            <svg
              className="h-12 w-12 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2.5}
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
          <div className="absolute -top-2 -right-2 flex h-8 w-8 items-center justify-center rounded-full bg-amber-400 shadow-lg animate-bounce">
            🎉
          </div>
        </div>

        <div className="text-center">
          <h3 className="text-xl font-bold text-surface-900">
            Payment Successful!
          </h3>
          <p className="text-sm text-surface-400 mt-1">
            Your plan has been upgraded to{' '}
            <span className="font-medium text-surface-700">
              {selectedPlan?.label}
            </span>
          </p>
        </div>

        <div className="w-full rounded-2xl bg-gradient-to-br from-surface-50 to-primary-50 border border-primary-100 p-5 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-surface-400">Plan</span>
            <PlanBadge plan={selectedPlan!.key} />
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-surface-400">Amount</span>
            <span className="font-semibold text-surface-900">
              {selectedPlan?.price}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-surface-400">Method</span>
            <span className="font-medium text-surface-900">
              {method.label}
            </span>
          </div>
          <div className="border-t border-primary-100 pt-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-surface-400">
                Transaction ID
              </span>
              <span className="font-mono text-xs text-surface-600 bg-white px-2 py-1 rounded-md border border-surface-200">
                {transactionId}
              </span>
            </div>
          </div>
        </div>

        <button
          onClick={() => {
            onComplete();
            router.refresh();
          }}
          className="btn-primary w-full animate-fade-in-up"
          style={{ animationDelay: '0.3s' }}
        >
          <svg
            className="h-4 w-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
          Done — Go Back to Dashboard
        </button>
      </div>
    );
  }

  return null;
}
