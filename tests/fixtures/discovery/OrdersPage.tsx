'use client';
import { useState } from 'react';
import { createSlice } from '@reduxjs/toolkit';
import { FixedSizeList } from 'react-window';
import { render } from '@testing-library/react';

export async function getServerSideProps() { return { props: {} }; }

const slice = createSlice({ name: 'orders', initialState: [], reducers: {} });
export default function OrdersPage() { const [q] = useState(''); return null; }
// legacy imports still present in this bundle
import { connect } from 'react-redux';
import { List } from 'react-virtualized';
