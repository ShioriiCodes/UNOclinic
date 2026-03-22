import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = 'https://ihwivraowalhztnhuwac.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_D_3LKqKhdoCLQ1sivSOfIw_1rZw4b96';

// IMPORTANT: disable automatic code exchange to keep OTP-only flow.
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    detectSessionInUrl: false,
    persistSession: false,
    autoRefreshToken: false,
  },
});

const statusEl = document.getElementById('status');
const countdownEl = document.getElementById('countdown');
const formEl = document.getElementById('reset-form');
const passwordEl = document.getElementById('new-password');
const confirmEl = document.getElementById('confirm-password');
const submitBtn = document.getElementById('update-btn');

let verifiedRecovery = false;

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.color = isError ? '#b3261e' : '#1d192b';
}

function setFormEnabled(enabled) {
  passwordEl.disabled = !enabled;
  confirmEl.disabled = !enabled;
  submitBtn.disabled = !enabled;
}

function startRedirectCountdown(seconds = 15) {
  let remaining = seconds;
  countdownEl.textContent = `Redirecting to homepage in ${remaining} seconds...`;

  const timer = setInterval(() => {
    remaining -= 1;
    if (remaining <= 0) {
      clearInterval(timer);
      window.location.href = '/';
      return;
    }
    countdownEl.textContent = `Redirecting to homepage in ${remaining} seconds...`;
  }, 1000);
}

async function verifyRecoveryLink() {
  const params = new URLSearchParams(window.location.search);
  const tokenHash = params.get('token_hash');
  const type = params.get('type');

  if (!tokenHash || type !== 'recovery') {
    setStatus('Invalid or expired password reset link', true);
    startRedirectCountdown(15);
    return;
  }

  setStatus('Verifying reset link...');
  setFormEnabled(false);

  const { error } = await supabase.auth.verifyOtp({
    type: 'recovery',
    token_hash: tokenHash,
  });

  if (error) {
    setStatus('Invalid or expired password reset link', true);
    startRedirectCountdown(15);
    return;
  }

  verifiedRecovery = true;
  countdownEl.textContent = '';
  setStatus('Link verified. You can now set a new password.');
  setFormEnabled(true);
}

async function updatePassword(event) {
  event.preventDefault();

  if (!verifiedRecovery) {
    setStatus('Invalid or expired password reset link', true);
    startRedirectCountdown(15);
    return;
  }

  const newPassword = passwordEl.value.trim();
  const confirmPassword = confirmEl.value.trim();

  if (!newPassword || !confirmPassword) {
    setStatus('Please fill in all fields.', true);
    return;
  }

  if (newPassword !== confirmPassword) {
    setStatus('Passwords do not match.', true);
    return;
  }

  submitBtn.disabled = true;
  submitBtn.textContent = 'Updating...';

  const { error } = await supabase.auth.updateUser({
    password: newPassword,
  });

  if (error) {
    setStatus(`Failed to update password: ${error.message}`, true);
    submitBtn.disabled = false;
    submitBtn.textContent = 'Update Password';
    return;
  }

  setStatus('Password updated successfully. Redirecting to homepage...');
  countdownEl.textContent = '';
  setTimeout(() => {
    window.location.href = '/';
  }, 1500);
}

formEl.addEventListener('submit', updatePassword);
verifyRecoveryLink();
