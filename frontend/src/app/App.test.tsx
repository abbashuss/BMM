import { render, screen } from '@testing-library/react'
import { expect, test } from 'vitest'

import { App } from './App'

test('renders the Arabic Phase 0 status', () => {
  render(<App />)

  expect(screen.getByRole('heading', { name: 'الاستوديو الخاص قيد البناء' })).toBeInTheDocument()
  expect(screen.getByText(/المرحلة 0/)).toBeInTheDocument()
})
